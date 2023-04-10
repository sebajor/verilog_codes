import numpy as np
import cocotb, sys, os
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
import cocotb_test.simulator
import pytest

###
### Author: Sebastian Jorquera
###

def pack_data(data, multiplex, nbits):
    out = 0
    for i in range(multiplex):
        out += (int(data[i])<<(i*nbits))
    return out

def unpack_data(data, mult, nbits=32):
    out = np.zeros(mult)
    for i in range(mult):
        aux = int(data>>(nbits*i))
        mask = 2**nbits-1
        dat = aux & mask
        out[i] = dat
    return out


@cocotb.test()
async def piso_test(dut, iters=200):
    ##TODO add lower limit for this parameters...
    ##also check how to add this as a parameter in pytest..
    burst_write_len=np.random.randint(20)
    sleep_write = np.random.randint(64)
    burst_read_len = np.random.randint(20)
    sleep_read=np.random.randint(10)
        
    #hdl hyperparameters
    din_width = int(dut.DIN_WIDTH)
    dout_width = int(dut.DOUT_WIDTH)
    multiplex = din_width//dout_width

    cocotb.log.info("din_widht:{:} dout_width:{:} burst write {:} sleep write {:} burst read {:} sleep read {:}".format(din_width, dout_width, 
                                    burst_write_len, sleep_write, burst_read_len, 
                                                           sleep_read))

    clk = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clk.start())
    dut.rst.value =0

    #data = np.arange(iters*multiplex)
    data = np.random.randint(size=iters*multiplex, low=0,high=2**dout_width-1)
    
    cocotb.start_soon(read_data(dut, data, dout_width, 
                                multiplex, burst_read_len,
                                sleep_read))
    await write_data(dut, data, dout_width, multiplex, 
                     burst_write_len, sleep_write)

async def read_data(dut, gold, dout_width, multiplex, burst_read_len, sleep_read):
    dut.dout_ready.value = 1
    count_ready = 0; count=0;
    await ClockCycles(dut.clk,2)
    while(count < len(gold)):
        ready = dut.dout_ready.value    ##take care when we are after a sleep
        dut.dout_ready.value = 1
        valid = int(dut.dout_valid.value)
        if(valid and ready):
            count_ready +=1
            dout = int(dut.dout.value)
            #dout = unpack_data(out, multiplex, nbits=dout_width)
            cocotb.log.debug("gold: %.2f \t rtl: %.2f"%(gold[count], dout))
            assert(dout==gold[count])
            count+=1
        if(count_ready==burst_read_len):
            count_ready=0;
            dut.dout_ready.value =0
            await ClockCycles(dut.clk, sleep_read-1)
        await ClockCycles(dut.clk,1)


async def write_data(dut, data, dout_width, multiplex, burst_write_len, sleep_write):
    dut.din_valid.value=0
    dut.din.value =0
    en_read=0
    await ClockCycles(dut.clk,2)
    for i in range(len(data)//multiplex):
        if((i%burst_write_len) == 0):
            dut.din_valid.value = 0
            await ClockCycles(dut.clk, sleep_write)
        dat = pack_data(data[i*multiplex:(i+1)*multiplex],
                        multiplex, nbits=int(dout_width))
        dut.din.value = dat
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)


@pytest.mark.parametrize("din_width", [64,128])
@pytest.mark.parametrize("dout_width", [16, 32])
def test_piso(request, din_width, dout_width):
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    prev_dir = os.path.split(tests_dir)[0]
    dut = 'piso'
    verilog_sources = [
        os.path.join(tests_dir, dut+'_tb.v'),
        os.path.join(tests_dir, dut+'.v'),
        os.path.join(prev_dir, 'skid_buffer/skid_buffer.v'),
        os.path.join(tests_dir, 'rtl/bram_infer.v')
        ]
    dut = dut+'_tb'
    parameters = {}
    parameters['DIN_WIDTH'] = din_width
    parameters['DOUT_WIDTH'] = dout_width

    cocotb_test.simulator.run(
        module = 'piso_test',
        verilog_sources = verilog_sources,
        toplevel = dut,
        parameters = parameters,
        timescale="1ns/1ns",    ##sometimes the clock doesnt start
        force_compile=True,     ##as we change parameters in the hdl we need to compile each time
        seed=10,
            )


