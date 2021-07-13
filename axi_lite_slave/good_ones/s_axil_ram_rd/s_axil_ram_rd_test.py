import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
import itertools
import numpy as np

AXI_PERIOD = 10
FPGA_PERIOD = 8

def setup_dut(dut):
    cocotb.fork(Clock(dut.axi_clock, AXI_PERIOD, units='ns').start())
    fpga_clk = Clock(dut.fpga_clk, FPGA_PERIOD, units='ns')
    cocotb.fork(fpga_clk.start())
    dut.rst <= 1
    dut.we <=0
    dut.bram_addr <=0
    dut.din <= 0
    dut.s_axil_araddr <= 0
    dut.s_axil_arprot <= 0
    dut.s_axil_arvalid <= 0
    dut.s_axil_rready <= 0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.rst)
    dut.s_axil_araddr <= 0
    dut.s_axil_arprot <= 0
    return axil_master

@cocotb.test()
async def s_axil_ram_rd_test(dut, iters=32):
    axil_master = setup_dut(dut)
    await RisingEdge(dut.axi_clock)
    dut.rst <= 0
    await Timer(AXI_PERIOD*10, units='ns')
    print("write the fpga side")
    await RisingEdge(dut.fpga_clk)
    gold = np.arange(iters)
    for i in range(iters):
        dut.we <=1
        dut.bram_addr <= int(i)
        dut.din <= int(i)
        await Timer(FPGA_PERIOD, units='ns')
    print('finish writting data')
    dut.we <=1
    cont = await read_continous(dut, iters, axil_master)
    assert ((cont == gold).all()), "Error continous reading"
    print(cont)
    np.random.seed(10)
    for i in range(32):
        pause_val = np.array(np.random.randint(1, 255), dtype=np.uint8)
        pause_bin = np.unpackbits(pause_val).tolist()
        print("iter:"+str(i)+"\t pause value: "+str(pause_bin))
        back = await read_backpreassure(dut, iters, axil_master, pause_bin)
        assert ((back == gold).all()),( "error backpreassure %i, pause %i" %(i, pause_val))
    #print(back)



async def read_continous(dut, iters, axil_master):
    words = await axil_master.read_dwords(0, iters)
    return words

async def read_backpreassure(dut, iters, axil_master, pause):
    axil_master.read_if.r_channel.set_pause_generator(itertools.cycle(pause))
    words = await axil_master.read_dwords(0, iters)
    return words
