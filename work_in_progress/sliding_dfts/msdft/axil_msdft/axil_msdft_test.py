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
    dut.din_re <=0
    dut.din_im <=0
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


async def write_data(dut, dat_re, dat_im, dft_len, k, din_width, din_pt, dout_width,
        dout_pt):
    """input data into the msdft and check the output value.. it doesnt make the assertion 
    """
    data_re = two_comp_pack(dat_re, din_width, din_pt)
    data_im = two_comp_pack(dat_im, din_width, din_pt)
    out_re = []; out_im =[]
    gold = msdft.msdft(dat_re+1j*dat_im, dft_len, k)
    await ClockCycles(dut.clk, 1)
    for i in range(len(dat_re)):
        dut.din_re <= int(data_re[i])
        dut.din_im <= int(data_im[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid.value)
        if(valid):
            dout_re = np.array(int(dut.dout_re.value))
            dout_im = np.array(int(dut.dout_im.value))
            dout_re = two_comp_unpack(dout_re, dout_width, dout_pt)
            dout_im = two_comp_unpack(dout_im, dout_width, dout_pt)
            out_re.append(dout_re)
            out_im.append(dout_im)
    for i in range(len(out_re)):
        print(i)
        print("gold_re: %.4f \t gold im: %.4f"%(gold[i].real, gold[i].imag))
        print("out re: %.4f \t \tout im: %.4f"%(out_re[i], out_im[i]))
        print("")
    return 1


async def write_twiddle_factors(dut, axil_master, dft_len, k):
    n =np.arange(dft_len)
    twidd = np.exp(-1j*2*np.pi*n*k/dft_len)
    aux = np.array([twidd.imag, twidd.real]).T.flatten()   #check order !!! im is the low, re is high
    aux = (aux*2**14).astype(int)
    aux_bin = struct.pack(str(2*dft_len)+'h', *(aux))
    aux2 = struct.unpack(str(dft_len)+'I', aux_bin)
    dut.din_valid <=1;
    dut.din_re <=0; dut.din_im <= 0;    ##this is better to reset everything
    dut.rst <= 0;
    await ClockCycles(dut.clk, 128) ##this is the full dft_len
    dut.din_valid <=0
    await ClockCycles(dut.clk, 20)
    wdata = await write_continous(dut, aux2, axil_master)


async def write_continous(dut, data, axil_master):
    wdata = await axil_master.write_dwords(0, data)
    return wdata


@cocotb.test()
async def axil_msdft_test(dut, iters=180, dft_len=128, k=55, din_width=8, din_pt=7,
        dout_width=32, dout_pt=21):

    axil_master = setup_dut(dut)
    dut.delay_line <= dft_len-1
    #dat_re = np.ones(iters)*0.5
    #dat_im = np.zeros(iters)
    #dat_re = np.zeros(iters)
    #dat_im = np.ones(iters)*0.5
    n = np.arange(iters)
    dat_re = 0.9*np.sin(2*np.pi*k*n/dft_len)
    dat_im = 0.1*np.sin(2*np.pi*k*n/dft_len)#np.zeros(iters)
    ###
    test = await write_data(dut, dat_re, dat_im, dft_len, k, din_width, 
            din_pt, dout_width, dout_pt)
    k = 20
    test_twidd = await write_twiddle_factors(dut, axil_master, dft_len, k)
    
    dat_re = 0.4*np.sin(2*np.pi*k*n/dft_len)
    dat_im = 0.4*np.sin(2*np.pi*k*n/dft_len)#np.zeros(iters)
    dut.rst <= 1
    await ClockCycles(dut.clk, 1)
    dut.rst <=0
    await ClockCycles(dut.clk, 1)
    test = await write_data(dut, dat_re, dat_im, dft_len, k, din_width, 
            din_pt, dout_width, dout_pt)
    








#async def re_write_twidd(dut, dft_len, k):
    """#write twiddle factors into the memory of the dut
    n =np.arange(dft_len)
    twidd = np.exp(-1j*2*np.pi*n*k/dft_len)
    twidd_re = twidd.real
    twidd_im = twidd.imag
    aux = np.array([twidd_im, twidd_re])    #check order !!! im is the low, re is high
    dut.din_valid <=1;
    dut.din_re <=0; dut.din_im <= 0;    ##this is better to reset everything
    dut.rst <= 0;
    await ClockCycles(dut.clk, 128)
    dut.din_valid <=0
    await ClockCycles(dut.clk, 20)
    dut.bram_we <= 1
    for i in range(len(twidd_re)):
        dat = two_pack_multiple(aux[:, i], 16, 14)
        dut.bram_dat <= int(dat)
        dut.bram_addr <= int(i)
        await ClockCycles(dut.axi_clock, 1)
    #now read the output
    dut.bram_we <=0
    await ClockCycles(dut.axi_clock, 2)
    for i in range(len(twidd_re)):
        dut.bram_addr <= int(i)
        await ClockCycles(dut.axi_clock, 1)
"""
