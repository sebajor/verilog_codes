import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
import struct, sys
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, two_pack_multiple


AXI_PERIOD = 10
FPGA_PERIOD = 8

def setup_dut(dut):
    clk = Clock(dut.clk, 10, units="ns")
    cocotb.fork(clk.start())
    axi_clk = Clock(dut.axi_clock, 5, units="ns")
    cocotb.fork(axi_clk.start())
    dut.rst.value =  0
    dut.din_valid.value = 0
    dut.din0_re.value = 1
    dut.din0_im.value = 1
    dut.din1_re.value = 1
    dut.din1_im.value = 1
    dut.axil_rst.value = 0
    dut.s_axil_araddr.value =  0
    dut.s_axil_arprot.value =  0
    dut.s_axil_arvalid.value =  0
    dut.s_axil_rready.value =  0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.rst)
    dut.s_axil_araddr.value =  0
    dut.s_axil_arprot.value =  0
    dut.s_axil_awaddr.value = 0
    dut.s_axil_awprot.value = 0
    dut.s_axil_wdata.value = 0
    dut.s_axil_wstrb.value = 0
    return axil_master

async def write_twidd_factor(dut, axil_master, dft_len, k, twidd_binpt=14):
    n =np.arange(dft_len)
    twidd = np.exp(-1j*2*np.pi*n*k/dft_len)
    aux = np.array([twidd.real, twidd.imag]).T.flatten()   #check order !!! im is the low, re is high
    aux = (aux*2**twidd_binpt).astype(int)
    aux_bin = struct.pack(str(2*dft_len)+'i', *(aux))
    aux2 = struct.unpack(str(2*dft_len)+'I', aux_bin)
    print(len(aux2))
    #dut.din_valid.value = 1;
    #dut.din_re.value = 0; dut.din_im.value =  0;    ##this is better to reset everything
    dut.rst.value =  0;
    await ClockCycles(dut.clk, 128) ##this is the full dft_len
    dut.din_valid.value = 0
    await ClockCycles(dut.clk, 20)
    wdata = await write_continous(dut, aux2, axil_master)

async def write_continous(dut, data, axil_master):
    wdata = await axil_master.write_dwords(0, data)
    return wdata


@cocotb.test()
async def single_bin_fx_correlator(dut, iters=128, k=55, acc_len=32,
                                   thresh=1):
    din_width = dut.DIN_WIDTH.value
    din_point = dut.DIN_POINT.value
    dout_width = dut.DOUT_WIDTH.value
    dout_point = dut.ACC_POINT.value
    dft_len = dut.DFT_LEN.value
    shift = dut.DFT_DOUT_SHIFT.value
    axil_master = setup_dut(dut)
    
    dut.delay_line.value =  dft_len-1
    dut.rst.value =  1
    dut.din_valid.value = 0
    await Timer(10, 'ns')
    await ClockCycles(dut.clk, 1)

    ###load a new twiddle factor with a new dft len
    dut.rst.value = 1
    dut.din_valid.value = 0
    dft_len = 512#72
    k = 20
    await ClockCycles(dut.clk,5)
    dut.delay_line.value =  dft_len-1
    dut.acc_len.value = acc_len-1
    await ClockCycles(dut.clk,5)
    
    await write_twidd_factor(dut, axil_master, dft_len, k)

    #random signal
    twidd = np.exp(-1j*2*np.pi*np.arange(dft_len)*k/dft_len)
    data0  = (np.random.random(size=(iters*acc_len, dft_len))-0.5)+1j*(np.random.random(size=(iters*acc_len, dft_len))-0.5)
    data1  = (np.random.random(size=(iters*acc_len, dft_len))-0.5)+1j*(np.random.random(size=(iters*acc_len, dft_len))-0.5)

    ##for real only test
    if(dut.REAL_INPUT_ONLY.value):
        data0 = data0.real
        data1 = data1.real
    #data = np.repeat(0.5*twidd**-1, iters).reshape(-1,iters).T
    dft0= data0 @ twidd
    dft1 = data1 @ twidd

    dft0 = dft0*(2**shift)
    dft1 = dft1*(2**shift)

    corr = dft0*np.conj(dft1)
    pow0 = (dft0*np.conj(dft0)).real
    pow1 = (dft1*np.conj(dft1)).real
    
    ##accumulation, check
    pow0_acc = np.sum(pow0.reshape((-1, acc_len)), axis=1)
    pow1_acc = np.sum(pow1.reshape((-1, acc_len)), axis=1)
    corr_acc = np.sum(corr.reshape((-1, acc_len)), axis=1)
    gold = [pow0_acc, pow1_acc, corr_acc]
    
    dat0_re = two_comp_pack(data0.real.flatten(), din_width, din_point)
    dat0_im = two_comp_pack(data0.imag.flatten(), din_width, din_point)
    dat0 = [dat0_re, dat0_im]

    dat1_re = two_comp_pack(data1.real.flatten(), din_width, din_point)
    dat1_im = two_comp_pack(data1.imag.flatten(), din_width, din_point)
    dat1 = [dat1_re, dat1_im]

    dat = [dat0, dat1]

    
    #after loading the twiddle factors rst it
    dut.rst.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0

    cocotb.fork(read_data(dut, gold, dout_width, dout_point, thresh))
    await write_data(dut, dat)


async def write_data(dut, dat):
    dat0_re = dat[0][0]
    dat0_im = dat[0][1]
    dat1_re = dat[1][0]
    dat1_im = dat[1][1]
    for i in range(len(dat0_re)):
        dut.din0_re.value = int(dat0_re[i])
        dut.din0_im.value = int(dat0_im[i])
        dut.din1_re.value = int(dat1_re[i])
        dut.din1_im.value = int(dat1_im[i])
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_width, dout_point, thresh):
    await ClockCycles(dut.clk, 1)
    pow0 = gold[0]
    pow1 = gold[1]
    corr = gold[2]
    count = 0
    while(count < len(gold[0])):
        valid = int(dut.dout_valid.value)
        if(valid):
            corr_re_rtl = int(dut.ab_re.value)
            corr_im_rtl = int(dut.ab_im.value)
            corr_re_rtl = two_comp_unpack(np.array(corr_re_rtl), dout_width, dout_point)
            corr_im_rtl = two_comp_unpack(np.array(corr_im_rtl), dout_width, dout_point)
            
            pow0_rtl = int(dut.aa.value)/2.**dout_point
            pow1_rtl = int(dut.bb.value)/2.**dout_point
            print("power0: {:.4f} \t {:.4f}".format(pow0[count], pow0_rtl))
            print("power1: {:.4f} \t {:.4f}".format(pow1[count], pow1_rtl))
            print("corr_re: {:.4f} \t {:.4f}".format(corr[count].real, corr_re_rtl))
            print("corr_im: {:.4f} \t {:.4f}".format(corr[count].imag, corr_im_rtl))
            print("\n")
            
            assert(np.abs(pow0[count]-pow0_rtl)<thresh)
            assert(np.abs(pow1[count]-pow1_rtl)<thresh)
            assert(np.abs(corr[count].real-corr_re_rtl)<thresh)
            assert(np.abs(corr[count].imag-corr_im_rtl)<thresh)

            count += 1

        await ClockCycles(dut.clk,1)









    


