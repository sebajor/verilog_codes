import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam
import struct, sys
sys.path.append('../../../cocotb_python')
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
    dut.din_re.value = 1
    dut.din_im.value = 1
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

async def write_twidd_factor(dut, axil_master, dft_len, k):
    n =np.arange(dft_len)
    twidd = np.exp(-1j*2*np.pi*n*k/dft_len)
    aux = np.array([twidd.imag, twidd.real]).T.flatten()   #check order !!! im is the low, re is high
    aux = (aux*2**14).astype(int)
    aux_bin = struct.pack(str(2*dft_len)+'h', *(aux))
    aux2 = struct.unpack(str(dft_len)+'I', aux_bin)
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
async def single_bin_dft_test(dut, iters=10, dft_len=128, k=55, din_width=16, din_point=15, dout_width=32, dout_point=15, thresh=0.1):
    axil_master = setup_dut(dut)
    
    dut.delay_line.value =  dft_len-1
    dut.rst.value =  1
    await ClockCycles(dut.clk, 1)

    ###load a new twiddle factor with a new dft len
    dut.rst.value = 1
    dut.din_valid.value = 0
    dft_len = 72
    k = 20
    await ClockCycles(dut.clk,5)
    dut.delay_line.value =  dft_len-1
    await ClockCycles(dut.clk,5)
    
    await write_twidd_factor(dut, axil_master, dft_len, k)

    twidd = np.exp(-1j*2*np.pi*np.arange(dft_len)*k/dft_len)
    data  = (np.random.random(size=(iters, dft_len))-0.5)+1j*(np.random.random(size=(iters, dft_len))-0.5)
    #data = np.repeat(0.5*twidd.imag, iters).reshape(-1,iters).T
    gold = data @ twidd

    
    dat_re = two_comp_pack(data.real.flatten(), din_width, din_point)
    dat_im = two_comp_pack(data.imag.flatten(), din_width, din_point)
    dat = [dat_re, dat_im]
    
    #after loading the twiddle factors rst it
    dut.rst.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0

    cocotb.fork(read_data(dut, gold, dout_width, dout_point, thresh))
    await write_data(dut, dat)


async def write_data(dut, dat):
    dat_re = dat[0]
    dat_im = dat[1]
    for i in range(len(dat_re)):
        dut.din_re.value = int(dat_re[i])
        dut.din_im.value = int(dat_im[i])
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_width, dout_point, thresh):
    await ClockCycles(dut.clk, 1)
    count = 0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            out_re = int(dut.dout_re.value)
            out_im = int(dut.dout_im.value)
            out_re = two_comp_unpack(np.array(out_re), dout_width, dout_point)
            out_im = two_comp_unpack(np.array(out_im), dout_width, dout_point)
            assert(np.abs(gold[count].real-out_re)<thresh)
            assert(np.abs(gold[count].imag-out_im)<thresh)
            #print(str(out_re+1j*out_im)+'\t'+str(gold[count]))
            count += 1
        await ClockCycles(dut.clk,1)









    


