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

    dut.s_cal_axil_araddr.value= 0
    dut.s_cal_axil_arprot.value= 0
    dut.s_cal_axil_arvalid.value= 0
    dut.s_cal_axil_rready.value= 0
    cal_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_cal_axil"), dut.axi_clock, dut.axi_reset)
    dut.s_cal_axil_araddr.value= 0
    dut.s_cal_axil_arprot.value= 0
    dut.s_cal_axil_awaddr.value=0
    dut.s_cal_axil_awprot.value=0
    dut.s_cal_axil_wdata.value=0
    dut.s_cal_axil_wstrb.value=0
    
    dut.s_synth_axil_araddr.value= 0
    dut.s_synth_axil_arprot.value= 0
    dut.s_synth_axil_arvalid.value= 0
    dut.s_synth_axil_rready.value= 0
    synth_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_synth_axil"), dut.axi_clock, dut.axi_reset)
    dut.s_synth_axil_araddr.value= 0
    dut.s_synth_axil_arprot.value= 0
    dut.s_synth_axil_awaddr.value=0
    dut.s_synth_axil_awprot.value=0
    dut.s_synth_axil_wdata.value=0
    dut.s_synth_axil_wstrb.value=0

    dut.din0_re.value =0; dut.din0_im.value =0;
    dut.din1_re.value =0; dut.din1_im.value =0;
    dut.din_valid.value=0

    dut.sync_in.value =0
    dut.cnt_rst.value =0
    dut.acc_len.value = acc_len
    await ClockCycles(dut.clk, 5)
    dut.cnt_rst.value = 1;
    await ClockCycles(dut.clk,10)
    dut.cnt_rst.value = 0
    await ClockCycles(dut.clk,10)

    return cal_master, synth_master


@cocotb.test()
async def axil_calibrator_test(dut, iters=10, acc_len=10, vector_len=512,
         din_width=18, din_point=17, coeff_width = 32, coeff_point=20,
         dout_width=64, dout_point=34, shift=0, thresh=0.5):
    
    #setup dut
    cal_master, synth_master= await setup_dut(dut, acc_len)
    await RisingEdge(dut.axi_clock)
    dut.axi_reset.value= 0
    await Timer(AXI_PERIOD*10, units='ns')

    ##create data
    np.random.seed(10)
    dat_re = np.random.random(size=(vector_len, iters*acc_len))-0.5
    dat_im = np.random.random(size=(vector_len, iters*acc_len))-0.5
    dat0 = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat0_b = np.array((dat_re_b, dat_im_b))
    
    dat_re = np.random.random(size=(vector_len, iters*acc_len))-0.5
    dat_im = np.random.random(size=(vector_len, iters*acc_len))-0.5
    dat1 = dat_re+1j*dat_im 

    dat_re_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    dat_im_b = two_comp_pack(dat_im.T.flatten(), din_width, din_point)
    dat1_b = np.array((dat_re_b, dat_im_b))

    coeff0 = np.random.random(size=vector_len)+1j*np.random.random(size=vector_len)-(0.5+1j*0.5)
    coeff1 = np.random.random(size=vector_len)+1j*np.random.random(size=vector_len)-(0.5+1j*0.5)
    ##to write the coefficients we need to express the data as 32bits words
    coef = np.vstack((coeff0.real, coeff0.imag, coeff1.real, coeff1.imag)).T.flatten()
    coef_b = two_comp_pack(coef, coeff_width, coeff_point)
    wdata = await write_continous(dut, coef_b.tolist(), cal_master)


    mult0 = dat0*(np.tile(coeff0, (iters*acc_len, 1)).T)
    mult1 = dat1*(np.tile(coeff1, (iters*acc_len, 1)).T)
    fft_in = mult0+mult1
     
    gold = fft_in*np.conj(fft_in)
    gold = np.sum(gold.reshape([vector_len, -1, acc_len]), axis=2)
    gold = np.abs(gold.T.flatten())

    cocotb.fork(write_data(dut, dat0_b, dat1_b, vector_len))
    await read_data(dut, synth_master, vector_len, gold, dout_point, thresh)


async def write_data(dut, dat0_b, dat1_b, vec_len):
    await RisingEdge(dut.clk)
    dut.sync_in.value = 0
    await ClockCycles(dut.clk, 1)
    ##for the spectrometer the sync_in also should be valid
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


async def read_data(dut, axil_master, vector_len, gold, dout_point, thresh):
    counter = 0
    await RisingEdge(dut.axi_clock)
    while(counter<(len(gold)/vector_len)):
        bram_rdy = dut.bram_ready.value 
        if(bram_rdy):
            rtl = await read_continous(dut, vector_len, axil_master)
            sub_gold = gold[counter*vector_len:(counter+1)*vector_len]
            errors = np.abs(np.array(rtl)/2**dout_point-sub_gold)
            print(np.array(rtl)/2**dout_point)
            print(sub_gold)
            assert (errors<thresh).all()
            counter +=1
        await ClockCycles(dut.axi_clock,1)

async def write_continous(dut, data, axil_master):
    wdata = await axil_master.write_dwords(0, data)
    return wdata

async def read_continous(dut, iters, axil_master):
    words = await axil_master.read_qwords(0, iters)
    return words
