import numpy as np
import cocotb, sys, os
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple
from itertools import cycle
import cocotb_test.simulator
import pytest

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def tge_write_packetizer_test(dut, iters=16):
    np.random.seed(10)
    din_width = int(dut.DIN_WIDTH)
    dout_width = 64
    multiplex = din_width//dout_width

    sleep_cycles = np.random.randint(low=10, high=64)
    sleep_write = np.random.randint(low=128, high=256)
    pkt_len = np.random.randint(low=128, high=1024)
    burst_write = np.random.randint(low=50, high=80)
    iters = np.random.randint(low=2, high=32)

    cocotb.log.info("din_width {:} multiplex {:} sleep_cycles {:} sleep_write {:} pkt_len {:} burst_write {:} iters {:}".format(
        din_width, multiplex, sleep_cycles, sleep_write, pkt_len, burst_write, iters))

    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clk.start())

    dut.din.value =0
    dut.din_valid.value =0;
    dut.rst.value =0
    dut.pkt_len.value = pkt_len-1
    dut.sleep_cycles.value = sleep_cycles-1

    #data = np.arange(burst_write*multiplex_in).reshape([-1,multiplex_in])
    data = np.random.randint(2**32-1, size=(burst_write*multiplex)).reshape([-1, multiplex])
    cocotb.start_soon(read_data(dut,data, burst_write*multiplex, 1, din_width, pkt_len))
    cocotb.start_soon(check_fifo_ovf(dut))
    await write_data(dut, data, din_width, multiplex,iters, burst_write, sleep_write)


async def check_fifo_ovf(dut):
    await ClockCycles(dut.clk, 10)
    while(1):
        ovf = int(dut.fifo_full.value)
        if(ovf):
            pytest.xfail("FIFO overflow")
        #assert (not ovf)
        await ClockCycles(dut.clk,1)


async def read_data(dut,gold,write_size, multiplex_out, din_width, pkt_len):
    counter =0
    #gold = np.arange(write_size)
    #gold = np.hstack(([0xaabbccdd,0,0xaabbccdd,0], gold.flatten()))
    gold = cycle(gold.flatten())
    await ClockCycles(dut.clk,1)
    while(1):
        valid = int(dut.tx_valid.value)
        eof = int(dut.tx_eof)
        if((counter%pkt_len==0) and counter!=0):
            assert (eof==1), 'eof is not high when it should!'
        if(eof):
            assert (valid ==1) , 'eof high but valid not!!!'
        if(valid):
            tx = int(dut.tx_data.value)
            gold_data = next(gold)
            cocotb.log.debug("gold: %.2f \t rtl:%.2f" %(tx, gold_data))
            assert(tx==gold_data)
        await ClockCycles(dut.clk,1)


async def write_data(dut, data, din_width, multiplex_in,iters, burst_write, sleep_write):
    for i in range(iters):
        dut.din.value =0
        dut.din_valid.value =0
        await ClockCycles(dut.clk, sleep_write)
        for j in range(data.shape[0]):
            dat = pack_multiple(data[j,:], multiplex_in, int(din_width//multiplex_in))
            dut.din.value = int(dat)
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)



@pytest.mark.parametrize("din_width", [128,256,512])
def test_piso(request, din_width):
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    prev_dir = os.path.split(os.path.split(tests_dir)[0])[0]
    dut = 'tge_write_packetizer'
    verilog_sources = [
        os.path.join(tests_dir, dut+'_tb.v'),
        os.path.join(tests_dir, dut+'.v'),
        os.path.join(prev_dir, 'utils/skid_buffer/skid_buffer.v'),
        os.path.join(prev_dir, 'utils/piso/rtl/bram_infer.v'),
        os.path.join(prev_dir, 'utils/piso/piso.v')
        ]
    dut = dut+'_tb'
    parameters = {}
    parameters['DIN_WIDTH'] = din_width

    cocotb_test.simulator.run(
        module = 'tge_write_packetizer_test',
        verilog_sources = verilog_sources,
        toplevel = dut,
        parameters = parameters,
        timescale="1ns/1ns",    ##sometimes the clock doesnt start
        force_compile=True,     ##as we change parameters in the hdl we need to compile each time
        seed=10,
            )
