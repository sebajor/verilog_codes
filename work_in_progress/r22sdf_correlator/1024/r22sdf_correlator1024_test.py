import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam


AXI_PERIOD = 10
FPGA_PERIOD = 8

def bit_reversal_indices(n):
    num_bits = int(np.log2(n))
    out = np.array([int(f'{i:0{num_bits}b}'[::-1], 2) for i in range(n)])
    return out

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

    dut.din0.value =0
    dut.din1.value =0
    dut.rst.value =0
    dut.acc_len.value = acc_len
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 1;
    await ClockCycles(dut.clk,10)
    dut.rst.value = 0
    await ClockCycles(dut.clk,10)
    return r11_master, r22_master, r12_master


@cocotb.test()
async def r22sdf_correlator1024_test(dut, iters=10, din_width=16, din_point=14,vector_len=1024,
        dout_width=64, dout_point=28, acc_len=10, shift=0, thresh=1.5):

    #setup dut
    r11_master, r22_master, r12_master = await setup_dut(dut, acc_len)
    axil_master = [r11_master, r22_master, r12_master]
    await RisingEdge(dut.axi_clock)
    dut.axi_reset.value= 0
    await Timer(AXI_PERIOD*10, units='ns')

    ##create data
    dat_re = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat0 = dat_re
    dat0_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    spect0 = np.fft.fft(dat0, axis=0)
    
    dat_re = np.random.random(size=(vector_len, acc_len*iters))-0.5
    dat1 = dat_re
    dat1_b = two_comp_pack(dat_re.T.flatten(), din_width, din_point)
    spect1 = np.fft.fft(dat1, axis=0)

    
    ind = bit_reversal_indices(vector_len)
    
    gold_r12 = spect0*np.conj(spect1)
    gold_r12 = np.sum(gold_r12.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r12 = gold_r12[ind, :]
    gold_r12 = gold_r12.T.flatten()

    gold_r11 = spect0*np.conj(spect0)
    gold_r11 = np.sum(gold_r11.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r11 = gold_r11[ind,:]
    gold_r11 = np.abs(gold_r11.T.flatten())
    
    gold_r22 = spect1*np.conj(spect1)
    gold_r22 = np.sum(gold_r22.reshape([vector_len, -1, acc_len]), axis=2)
    gold_r22 = gold_r22[ind,:]
    gold_r22 = np.abs(gold_r22.T.flatten())

    gold = [gold_r11, gold_r22, gold_r12]

    
    cocotb.fork(write_data(dut, dat0_b, dat1_b, vector_len))
    await read_data(dut, axil_master, vector_len, gold,dout_width, dout_point, thresh)

    


async def write_data(dut, dat0_b,dat1_b, vec_len):
    dut.din_valid.value = 1
    for i in range(len(dat0_b)):
        dut.din0.value = int(dat0_b[i])
        dut.din1.value = int(dat1_b[i])
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




