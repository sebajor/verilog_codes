import cocotb, struct
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles
import matplotlib.pyplot as plt
import msdft
from two_comp import two_comp_pack, two_comp_unpack, two_pack_multiple
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam

AXI_PERIOD = 10
FPGA_PERIOD = 8

def setup_dut(dut):
    clk = Clock(dut.clk, 10, units="ns")
    cocotb.fork(clk.start())
    axi_clk = Clock(dut.axi_clock, 5, units="ns")
    cocotb.fork(axi_clk.start())
    dut.rst <= 0
    dut.din_valid <=0
    dut.din1_re <=0
    dut.din1_im <=0
    dut.din2_re <=0
    dut.din2_im <=0
    dut.axil_rst <=0
    dut.s_axil_araddr <= 0
    dut.s_axil_arprot <= 0
    dut.s_axil_arvalid <= 0
    dut.s_axil_rready <= 0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.rst)
    dut.s_axil_araddr <= 0
    dut.s_axil_arprot <= 0
    dut.s_axil_awaddr <=0
    dut.s_axil_awprot <=0
    dut.s_axil_wdata <=0
    dut.s_axil_wstrb <=0
    return axil_master


async def write_data(dut, dat1, dat2, dft_len, k, din_width, din_pt, dout_width,
        dout_pt, acc_len):
    """input data into the msdft and check the output value.. it doesnt make the assertion 
    """
    data1_re = two_comp_pack(dat1.real, din_width, din_pt)
    data1_im = two_comp_pack(dat1.imag, din_width, din_pt)
    data2_re = two_comp_pack(dat2.real, din_width, din_pt)
    data2_im = two_comp_pack(dat2.imag, din_width, din_pt) 
    pow1, pow2, corr = msdft.msdft_correlator(dat1,dat2, dft_len, k)
    r11_gold = np.sum(pow1.reshape([-1,acc_len]), axis=1)
    r22_gold = np.sum(pow2.reshape([-1,acc_len]), axis=1)
    r12_gold = np.sum(corr.reshape([-1,acc_len]), axis=1)
    rtl_r11=[]; rtl_r22=[]; rtl_r12_re=[]; rtl_r12_im=[]
    await ClockCycles(dut.clk, 1)
    print(r11_gold.shape)
    print(pow1[500])
    for i in range(len(data1_re)):
        dut.din1_re <= int(data1_re[i])
        dut.din1_im <= int(data1_im[i])
        dut.din2_re <= int(data2_re[i])
        dut.din2_im <= int(data2_im[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid.value)
        if(valid):
            r11 = np.array(int(dut.r11.value)/2.**dout_pt)
            r22 = np.array(int(dut.r22.value)/2.**dout_pt)
            r12_re = np.array(int(dut.r12_re.value))
            r12_im = np.array(int(dut.r12_im.value))
            r12_re = two_comp_unpack(r12_re, dout_width, dout_pt)
            r12_im = two_comp_unpack(r12_im, dout_width, dout_pt)
            rtl_r11.append(r11)
            rtl_r22.append(r22)
            rtl_r12_re.append(r12_re)
            rtl_r12_im.append(r12_im)
    for i in range(len(rtl_r12_re)):
        print(i)
        print("gold r12_re: %.4f \t gold r11_im: %.4f"%(r12_gold[i].real, r12_gold[i].imag))
        print("r12 re: %.4f \t \t r12 im: %.4f"%(rtl_r12_re[i], rtl_r12_im[i]))
        print("gold r11: %.4f \t gold r22: %.4f" %(r11_gold[i], r22_gold[i]))
        print("r11: %.4f \t r22: %.4f"%(rtl_r11[i], rtl_r22[i]))
        print("\n")
    return 1



@cocotb.test()
async def msdft_correlator_test(dut, iters=180, dft_len=128, k=55, din_width=8, din_pt=7,
        dout_width=32, dout_pt=7):
    acc_len = 5
    axil_master = setup_dut(dut)
    dut.acc_len <= acc_len
    dut.delay_line <= dft_len-1
    n = np.arange(iters*(acc_len+2))
    phase = -95
    dat1 = 0.9*np.exp(1j*(2*np.pi*k*n/dft_len+np.deg2rad(phase)))
    dat2 = 0.9*np.exp(1j*2*np.pi*k*n/dft_len)
    test = await write_data(dut, dat1, dat2, dft_len, k, din_width,
            din_pt, dout_width, dout_pt, acc_len)

