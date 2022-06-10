import cocotb, struct, sys
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles
import matplotlib.pyplot as plt
sys.path.append('../')
import msdft
sys.path.append('../../../cocotb_python')
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


async def write_twidd_factor(dut, axil_master, dft_len, k):
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
        dout_width=32, dout_pt=21, thresh=1):
    axil_master = setup_dut(dut)
    dut.delay_line <= dft_len-1
    dut.rst <= 1
    await ClockCycles(dut.clk, 1)
    angle = 0

    ###charge a new twiddle factor with a new dft len
    dut.rst <=1
    dut.din_valid <=0
    dft_len = 72
    k = 20
    await ClockCycles(dut.clk,5)
    dut.delay_line <= dft_len-1
    await ClockCycles(dut.clk,5)

    await write_twidd_factor(dut, axil_master, dft_len, k)
    n = np.arange(iters)
    dat = 0.9*np.exp(1j*(2*np.pi*k*n/dft_len+np.deg2rad(angle)))
    dat_re = dat.real
    dat_im = dat.imag
    din_re = two_comp_pack(dat_re, din_width, din_pt)
    din_im = two_comp_pack(dat_im, din_width, din_pt)
    gold = msdft.msdft(dat_re+1j*dat_im, dft_len,k)

    ##after charge the wights rst to match the gold values
    dut.rst <= 1
    dut.din_valid <=0
    await ClockCycles(dut.clk,5)
    dut.rst <= 0

    cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    await continous_write(dut, din_re, din_im)

    

async def read_data(dut, gold, dout_width, dout_pt, thresh):
    await ClockCycles(dut.clk,2)
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            out_re = int(dut.dout_re.value)
            out_im = int(dut.dout_im.value)
            out_re = two_comp_unpack(np.array(out_re), dout_width, dout_pt)
            out_im = two_comp_unpack(np.array(out_im), dout_width, dout_pt)
            assert (np.abs(out_re-gold[count].real)<thresh) , "Error! "
            assert (np.abs(out_im-gold[count].imag)<thresh) , "Error! "
            print(str(out_re+1j*out_im)+"\t"+str(gold[count]))
            count +=1
        await ClockCycles(dut.clk,1)


async def continous_write(dut, dat_re, dat_im):
    for i in range(len(dat_re)):
        dut.din_re <= int(dat_re[i])
        dut.din_im <= int(dat_im[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk,1)


async def burst_write(dut, dat_re, dat_im, burst_len):
    for i in range(len(dat_re)):
        if(i%burst_len==0):
            for j in range(2):
                dut.din_valid <=0
                await ClockCycles(dut.clk, 1)
            dut.din_re <= int(dat_re[i])
            dut.din_im <= int(dat_im[i])
            dut.din_valid <=1
            await ClockCycles(dut.clk, 1)

