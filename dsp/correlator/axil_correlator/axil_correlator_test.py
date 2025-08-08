import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
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

    dut.s_r11_axil_araddr.value= 0
    dut.s_r11_axil_arprot.value= 0
    dut.s_r11_axil_arvalid.value= 0
    dut.s_r11_axil_rready.value= 0
    r11_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_r11_axil"), dut.axi_clock, dut.axi_reset)
    dut.s_r11_axil_araddr.value= 0
    dut.s_r11_axil_arprot.value= 0
    dut.s_r11_axil_awaddr.value=0
    dut.s_r11_axil_awprot.value=0
    dut.s_r11_axil_wdata.value=0
    dut.s_r11_axil_wstrb.value=0
    
    dut.s_r22_axil_araddr.value= 0
    dut.s_r22_axil_arprot.value= 0
    dut.s_r22_axil_arvalid.value= 0
    dut.s_r22_axil_rready.value= 0
    r22_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_r22_axil"), dut.axi_clock, dut.axi_reset)
    dut.s_r22_axil_araddr.value= 0
    dut.s_r22_axil_arprot.value= 0
    dut.s_r22_axil_awaddr.value=0
    dut.s_r22_axil_awprot.value=0
    dut.s_r22_axil_wdata.value=0
    dut.s_r22_axil_wstrb.value=0

    dut.s_r12_axil_araddr.value= 0
    dut.s_r12_axil_arprot.value= 0
    dut.s_r12_axil_arvalid.value= 0
    dut.s_r12_axil_rready.value= 0
    r12_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_r12_axil"), dut.axi_clock, dut.axi_reset)
    dut.s_r12_axil_araddr.value= 0
    dut.s_r12_axil_arprot.value= 0
    dut.s_r12_axil_awaddr.value=0
    dut.s_r12_axil_awprot.value=0
    dut.s_r12_axil_wdata.value=0
    dut.s_r12_axil_wstrb.value=0

    dut.din0_re.value =0; dut.din0_im.value =0;
    dut.din1_re.value =0; dut.din1_im.value =0;
    dut.sync_in.value =0
    dut.cnt_rst.value =0
    dut.acc_len.value = acc_len
    await ClockCycles(dut.clk, 5)
    dut.cnt_rst.value = 1;
    await ClockCycles(dut.clk,10)
    dut.cnt_rst.value = 0
    await ClockCycles(dut.clk,10)
    return r11_master, r22_master, r12_master


@cocotb.test()
async def axi_correlator_test(dut, iters=10, din_width=18, din_point=17,vector_len=512,
        dout_width=64, dout_point=34, acc_len=10, shift=0, thresh=0.5):
    
    #setup dut
    r11_master, r22_master, r12_master = await setup_dut(dut, acc_len)
    axil_master = [r11_master, r22_master, r12_master]
    await RisingEdge(dut.axi_clock)
    dut.axi_reset.value= 0
    await Timer(AXI_PERIOD*10, units='ns')

    ##create data
    dat_re = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat_im = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat0 = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat0_b = np.array((dat_re_b, dat_im_b))
    
    dat_re = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat_im = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat1 = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat1_b = np.array((dat_re_b, dat_im_b))


    gold_r12 = dat0*np.conj(dat1)
    gold_r12 = np.sum(gold_r12.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r12 = gold_r12.T.flatten()

    gold_r11 = dat0*np.conj(dat0)
    gold_r11 = np.sum(gold_r11.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r11 = np.abs(gold_r11.T.flatten())
    
    gold_r22 = dat1*np.conj(dat1)
    gold_r22 = np.sum(gold_r22.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r22 = np.abs(gold_r22.T.flatten())

    gold = [gold_r11, gold_r22, gold_r12]

    
    cocotb.fork(write_data(dut, dat0_b, dat1_b, vector_len))
    await read_data(dut, axil_master, vector_len, gold,dout_width, dout_point, thresh)

    


async def write_data(dut, dat0_b,dat1_b, vec_len):
    await RisingEdge(dut.clk)
    dut.sync_in.value = 0
    await ClockCycles(dut.clk, 1)
    dut.sync_in.value = 1
    dut.din_valid.value = 1
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 0
    for i in range(len(dat0_b[1])):
        dut.din0_re.value = int(dat0_b[0][i])
        dut.din0_im.value = int(dat0_b[1][i])
        dut.din1_re.value = int(dat1_b[0][i])
        dut.din1_im.value = int(dat1_b[1][i])
        await ClockCycles(dut.clk,1)


async def read_data(dut, axil_master, vector_len, gold,dout_width, dout_point, thresh):
    counter = 0
    await RisingEdge(dut.axi_clock)
    while(counter<(len(gold[0])/vector_len)):
        bram_rdy = dut.bram_ready.value 
        if(bram_rdy):
            rtl = await read_continous(dut, vector_len, axil_master[0])
            rtl = two_comp_unpack(np.array(rtl), dout_width, dout_point)
            sub_gold = gold[0][counter*vector_len:(counter+1)*vector_len]
            errors = np.abs(rtl-sub_gold)
            assert (errors<thresh).all()
            rtl = await read_continous(dut, vector_len, axil_master[1])
            rtl = two_comp_unpack(np.array(rtl), dout_width, dout_point)
            sub_gold = gold[1][counter*vector_len:(counter+1)*vector_len]
            errors = np.abs(rtl-sub_gold)
            assert (errors<thresh).all()

            rtl = await read_continous(dut, 2*vector_len, axil_master[2])
            rtl = two_comp_unpack(np.array(rtl), dout_width, dout_point)
            rtl = rtl[::2]+1j*rtl[1::2]
            sub_gold = gold[2][counter*vector_len:(counter+1)*vector_len]
            print(rtl)
            errors = np.abs(rtl-sub_gold)
            assert (errors<thresh).all()
            counter +=1
        await ClockCycles(dut.axi_clock,1)
        

async def read_continous(dut, iters, axil_master):
    words = await axil_master.read_qwords(0, iters)
    return words
