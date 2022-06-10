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
    dut.rst.value = 0
    dut.din_valid.value =0
    dut.din1_re.value =0
    dut.din1_im.value =0
    dut.din2_re.value =0
    dut.din2_im.value =0
    dut.axil_rst.value =0
    dut.s_axil_araddr.value = 0
    dut.s_axil_arprot.value = 0
    dut.s_axil_arvalid.value = 0
    dut.s_axil_rready.value = 0
    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axi_clock, dut.rst)
    dut.s_axil_araddr.value = 0
    dut.s_axil_arprot.value = 0
    dut.s_axil_awaddr.value =0
    dut.s_axil_awprot.value =0
    dut.s_axil_wdata.value =0
    dut.s_axil_wstrb.value =0
    dut.acc_len.value =  1
    return axil_master


async def write_twidd_factor(dut, axil_master, dft_len, k):
    n =np.arange(dft_len)
    twidd = np.exp(-1j*2*np.pi*n*k/dft_len)
    aux = np.array([twidd.imag, twidd.real]).T.flatten()   #check order !!! im is the low, re is high
    aux = (aux*2**14).astype(int)
    aux_bin = struct.pack(str(2*dft_len)+'h', *(aux))
    aux2 = struct.unpack(str(dft_len)+'I', aux_bin)
    dut.din_valid.value =0;
    dut.rst.value =0
    await ClockCycles(dut.clk, 20)
    wdata = await write_continous(dut, aux2, axil_master)


async def write_continous(dut, data, axil_master):
    wdata = await axil_master.write_dwords(0, data)
    return wdata


@cocotb.test()
async def axil_msdft_test(dut, iters=40, acc_len=5, dft_len=2**13, k=55, din_width=14, din_pt=13,
        dout_width=32, dout_pt=12, thresh=1000):
    axil_master = setup_dut(dut)
    dut.delay_line.value = dft_len-1
    dut.rst.value = 0
    
    dut.acc_len.value = acc_len
    await ClockCycles(dut.clk, 1)
    angle = -50

    ###charge a new twiddle factor with a new dft len
    dft_old_len = dft_len
    dft_len = 1000
    k = 100
    await ClockCycles(dut.clk,5)
    dut.delay_line.value = dft_len-1
    dut.acc_len.value = acc_len
    await ClockCycles(dut.clk,5)

    await write_twidd_factor(dut, axil_master, dft_len, k)
    dut.rst.value = 1
    await ClockCycles(dut.clk, dft_old_len)

    n = np.arange(iters*acc_len)

    dat1 = 0.98*np.exp(1j*(2*np.pi*k*n/dft_len))
    dat1_re = dat1.real
    dat1_im = dat1.imag
    din1_re = two_comp_pack(dat1_re, din_width, din_pt)
    din1_im = two_comp_pack(dat1_im, din_width, din_pt)
    msdft1 = msdft.msdft(dat1, dft_len,k)
    
    dat2 = 0.7*np.exp(1j*(2*np.pi*k*n/dft_len+np.deg2rad(angle)))
    dat2_re = dat2.real
    dat2_im = dat2.imag
    din2_re = two_comp_pack(dat2_re, din_width, din_pt)
    din2_im = two_comp_pack(dat2_im, din_width, din_pt)
    msdft2 = msdft.msdft(dat2, dft_len,k)


    r11 = msdft1*np.conj(msdft1)
    r22 = msdft2*np.conj(msdft2)
    r12 = msdft1*np.conj(msdft2)

    r11_acc = np.sum(r11.reshape([-1, acc_len]), axis=1)
    r22_acc = np.sum(r22.reshape([-1, acc_len]), axis=1)
    r12_acc = np.sum(r12.reshape([-1, acc_len]), axis=1)

    #print(r11[:10].real)
    #print(r11_acc.real[0])
    gold = [r11_acc, r22_acc, r12_acc]

    ##after charge the wights rst to match the gold values
    dut.rst.value = 0
    dut.din_valid.value =0
    await ClockCycles(dut.clk,10)

    #cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    #await continous_write(dut, din1_re, din1_im, din2_re, din2_im)
    cocotb.fork(continous_write(dut, din1_re, din1_im, din2_re, din2_im))
    await read_data(dut, gold, dout_width, dout_pt, thresh)



async def read_data(dut, gold, dout_width, dout_pt, thresh):
    await ClockCycles(dut.clk,2)
    count =0
    while(count < len(gold[0])):
        valid = int(dut.dout_valid.value)
        if(valid):
            r11 = int(dut.r11.value)
            r22 = int(dut.r22.value)
            r12_re = int(dut.r12_re.value)
            r12_im = int(dut.r12_im.value)
            #
            r11 = two_comp_unpack(np.array(r11), dout_width, dout_pt)
            r22 = two_comp_unpack(np.array(r22), dout_width, dout_pt)
            r12_re = two_comp_unpack(np.array(r12_re), dout_width, dout_pt)
            r12_im = two_comp_unpack(np.array(r12_im), dout_width, dout_pt)
            print('r11:%2.f \t r12_re: %.2f \t r12_im:%.2f \t r22:%.2f' %(r11,r12_re, r12_im, r22))
            print('r11:%2.f \t r12_re: %.2f \t r12_im:%.2f \t r22:%.2f' %(gold[0][count].real,gold[2][count].real,gold[2][count].imag, gold[1][count].real))
            print('angle %.4f \n' %(np.rad2deg(np.angle(r12_re+1j*r12_im))))
            
            #assertions
            assert ((np.abs(r11-gold[0][count].real))<thresh), 'Error r11'
            assert ((np.abs(r22-gold[1][count].real))<thresh), 'Error r22'
            assert ((np.abs(r12_re-gold[2][count].real))<thresh), 'Error r12 real'
            assert ((np.abs(r12_im-gold[2][count].imag))<thresh), 'Error r12 imag'
            #print(str(out_re+1j*out_im)+"\t"+str(gold[count]))
            count +=1
        await ClockCycles(dut.clk,1)


async def continous_write(dut, dat1_re, dat1_im, dat2_re, dat2_im):
    for i in range(len(dat1_re)):
        dut.din1_re.value = int(dat1_re[i])
        dut.din1_im.value = int(dat1_im[i])
        dut.din2_re.value = int(dat2_re[i])
        dut.din2_im.value = int(dat2_im[i])
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)
