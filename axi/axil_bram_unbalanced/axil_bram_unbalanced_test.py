import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
import itertools, random
import numpy as np

AXI_PERIOD = 10
FPGA_PERIOD = 8

def setup_dut(dut):
    cocotb.fork(Clock(dut.axi_clock, AXI_PERIOD, units='ns').start())
    fpga_clk = Clock(dut.fpga_clk, FPGA_PERIOD, units='ns')
    cocotb.fork(fpga_clk.start())
    dut.rst.value= 1
    dut.bram_we.value=0
    dut.bram_addr.value=0
    dut.bram_din.value= 0
    dut.s_axil_araddr.value= 0
    dut.s_axil_arprot.value= 0
    dut.s_axil_arvalid.value= 0
    dut.s_axil_rready.value= 0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.rst)
    dut.s_axil_araddr.value= 0
    dut.s_axil_arprot.value= 0
    dut.s_axil_awaddr.value=0
    dut.s_axil_awprot.value=0
    dut.s_axil_wdata.value=0
    dut.s_axil_wstrb.value=0
    return axil_master

@cocotb.test()
async def axil_bram(dut, iters=32):
    axil_master = setup_dut(dut)
    await RisingEdge(dut.axi_clock)
    dut.rst.value= 0
    await Timer(AXI_PERIOD*10, units='ns')
    print("write the fpga side")
    await RisingEdge(dut.fpga_clk)
    gold = np.arange(iters)
    for i in range(iters):
        dut.bram_we.value=1
        dut.bram_addr.value= int(i)
        dut.bram_din.value= int((2*i+1)<<32)+int(2*i)
        await Timer(FPGA_PERIOD, units='ns')
    print('finish writting data')
    await RisingEdge(dut.axi_clock)
    dut.bram_we.value=0
    cont = await read_continous(dut, iters, axil_master)
    assert ((cont == gold).all()), "Error continous reading"
    print(cont)
    #print(back 
    np.random.seed(10)
    for i in range(32):
        pause_val = np.array(np.random.randint(1, 255), dtype=np.uint8)
        pause_bin = np.unpackbits(pause_val).tolist()
        print("iter:"+str(i)+"\t pause value: "+str(pause_bin))
        back = await read_backpreassure(dut, iters, axil_master, pause_bin)
        assert ((back == gold).all()),( "error backpreassure %i, pause %i" %(i, pause_val))
    test_data = [x+1 for x in range(iters)]
    gold = np.array(test_data)
    wdata = await write_continous(dut, test_data, axil_master)
    #wdata = await axil_master.write_dwords(0, test_data)
    #rdata = await axil_master.read_dwords(0, iters)
    rdata = await read_continous(dut, iters, axil_master)
    assert (gold == rdata).all(), "error continous w/r"
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
        assert (gold==rdata).all(), ("backpreassure w/r in %i, \t pauses: %i %i " %(i, pause_w, pause_r))
    #collision
    await RisingEdge(dut.axi_clock)
    await ClockCycles(dut.axi_clock,2)
    dut.s_axil_arvalid.value= 1
    dut.s_axil_araddr.value= 0
    await ClockCycles(dut.axi_clock,1)
    dut.s_axil_awvalid.value=1
    dut.s_axil_wvalid.value= 1
    dut.s_axil_awaddr.value=0
    dut.s_axil_wdata.value= 0xaabbccdd
    for i in range(10):
        dut.s_axil_arvalid.value= 1
        dut.s_axil_awvalid.value=1
        dut.s_axil_wvalid.value= 1
        await ClockCycles(dut.axi_clock, 1)

async def read_continous(dut, iters, axil_master):
    words = await axil_master.read_dwords(0, iters)
    return words

async def read_backpreassure(dut, iters, axil_master, pause):
    axil_master.read_if.r_channel.set_pause_generator(itertools.cycle(pause))
    words = await axil_master.read_dwords(0, iters)
    return words

async def write_continous(dut, data, axil_master):
    wdata = await axil_master.write_dwords(0, data)
    return wdata

async def write_backpreassure(dut, data, axil_master, pause_aw, pause_w):
    axil_master.write_if.aw_channel.set_pause_generator(itertools.cycle(pause_aw))
    axil_master.write_if.w_channel.set_pause_generator(itertools.cycle(pause_w))
    wdata = await axil_master.write_dwords(0, data)
    return wdata
