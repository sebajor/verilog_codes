import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
import itertools, random
import numpy as np

AXI_PERIOD = 10

def setup_dut(dut):
    cocotb.fork(Clock(dut.axi_clock, AXI_PERIOD, units='ns').start())
    dut.rst <= 1
    dut.s_axil_araddr <= 0
    dut.s_axil_arprot <= 0
    dut.s_axil_arvalid <= 0
    dut.s_axil_rready <= 0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.rst)
    dut.s_axil_araddr <= 0
    dut.s_axil_arprot <= 0
    dut.s_axil_awprot <= 0
    dut.s_axil_awaddr <=0
    dut.s_axil_wdata <=0
    dut.s_axil_wstrb <=0
    return axil_master

@cocotb.test()
async def s_axil_reg_test(dut, iters=32):
    axil_master = setup_dut(dut)
    await RisingEdge(dut.axi_clock)
    dut.rst <= 0;
    await Timer(AXI_PERIOD*5, units='ns')
    print("write continous")
    #for i in range(iters):
    #    await axil_master.write_word(i,i)
    test_data = [x for x in range(iters)]
    gold = np.array(test_data)
    wdata = await write_continous(dut, test_data, axil_master)
    #wdata = await axil_master.write_dwords(0, test_data)
    #rdata = await axil_master.read_dwords(0, iters)
    rdata = await read_continous(dut, iters, axil_master)
    assert (gold == rdata).all(), "error continous r/w"
    random.seed(10)
    for i in range(32):
        pause_w = np.array(np.random.randint(1, 255), dtype=np.uint8)
        pause_bin_w = np.unpackbits(pause_w).tolist()
        pause_r = np.array(np.random.randint(1, 255), dtype=np.uint8)
        pause_bin_r = np.unpackbits(pause_r).tolist()
        test_data = random.sample(range(0, 2**32-1), iters)
        wdata = await write_backpreassure(dut, test_data, axil_master, pause_bin_w, pause_bin_w)
        rdata = await read_backpreassure(dut, iters, axil_master, pause_bin_r)
        gold = np.array(test_data)
        #print(rdata)
        #print(test_data)
        assert (gold==rdata).all(), ("Fail in %i, \t pauses: %i %i " %(i, pause_w, pause_r))


async def write_continous(dut, data, axil_master):
    wdata = await axil_master.write_dwords(0, data)
    return wdata


async def read_continous(dut, iters, axil_master):
    words = await axil_master.read_dwords(0, iters)
    return words

async def write_backpreassure(dut, data, axil_master, pause_aw, pause_w):
    axil_master.write_if.aw_channel.set_pause_generator(itertools.cycle(pause_aw))
    axil_master.write_if.w_channel.set_pause_generator(itertools.cycle(pause_w))
    wdata = await axil_master.write_dwords(0, data)
    return wdata

async def read_backpreassure(dut, iters, axil_master, pause):
    axil_master.read_if.r_channel.set_pause_generator(itertools.cycle(pause))
    words = await axil_master.read_dwords(0, iters)
    return words


