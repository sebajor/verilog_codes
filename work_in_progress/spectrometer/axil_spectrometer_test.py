import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam


###
### Author:Sebastian Jorquera
###

AXI_PERIOD = 10
FPGA_PERIOD = 8

async def setup_dut(dut, acc_len):
    cocotb.fork(Clock(dut.axi_clock, AXI_PERIOD, units='ns').start())
    fpga_clk = Clock(dut.clk, FPGA_PERIOD, units='ns')
    cocotb.fork(fpga_clk.start())
    dut.axi_reset.value= 1
    dut.s_axil_araddr.value= 0
    dut.s_axil_arprot.value= 0
    dut.s_axil_arvalid.value= 0
    dut.s_axil_rready.value= 0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.axi_reset)
    dut.s_axil_araddr.value= 0
    dut.s_axil_arprot.value= 0
    dut.s_axil_awaddr.value=0
    dut.s_axil_awprot.value=0
    dut.s_axil_wdata.value=0
    dut.s_axil_wstrb.value=0
    
    dut.din_re.value =0; dut.din_im.value =0;
    dut.sync_in.value =0
    dut.cnt_rst.value =0
    dut.acc_len.value = acc_len
    await ClockCycles(dut.clk, 5)
    dut.cnt_rst.value = 1;
    await ClockCycles(dut.clk,10)
    dut.cnt_rst.value = 0
    await ClockCycles(dut.clk,10)

    return axil_master


@cocotb.test()
async def spectrometer_lane_test(dut, iters=1, din_width=18, din_point=17,vector_len=16,
        dout_width=64, dout_point=34, acc_len=2, shift=0, thresh=0.5):
    
    #setup dut
    axil_master = await setup_dut(dut, acc_len)
    await RisingEdge(dut.axi_clock)
    dut.axi_reset.value= 0
    await Timer(AXI_PERIOD*10, units='ns')


    ##create data
    np.random.seed(10)
    #dat_re = np.random.random(size=(vector_len, acc_len*iters))
    #dat_im = np.random.random(size=(vector_len, acc_len*iters))
    dat_re = np.tile(np.arange(vector_len)/vector_len,acc_len*iters).reshape((acc_len*iters, vector_len)).T
    dat_im = np.zeros((vector_len, acc_len*iters))
    
    dat = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat_b = np.array((dat_re_b, dat_im_b))
    
    gold = dat*np.conj(dat)
    gold = np.sum(gold.reshape([vector_len, -1, acc_len]), axis=2)
    gold = np.abs(gold.T.flatten())
    
    await write_data(dut, dat_b, vector_len)
    await ClockCycles(dut.clk, 530) 
    ##not that easy.. the bram gets write before I can read it :P
    rdata = await read_continous(dut, vector_len, axil_master)
    np.save('rdata.npy',rdata)


async def write_data(dut, dat_b, vec_len):
    await RisingEdge(dut.clk)
    dut.sync_in.value = 0
    await ClockCycles(dut.clk, 1)
    dut.sync_in.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
    for i in range(len(dat_b[1])):
        dut.din_re.value = int(dat_b[0][i])
        dut.din_im.value = int(dat_b[1][i])
        await ClockCycles(dut.clk,1)

async def read_continous(dut, iters, axil_master):
    words = await axil_master.read_qwords(0, iters)
    return words
