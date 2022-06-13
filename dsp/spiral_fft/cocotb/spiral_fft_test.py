import numpy as np
import matplotlib.pyplot as plt
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
from scipy.fftpack import fft
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def spiral_fft_test(dut, din_width=16, dout_width=16):
    np.random.seed(19)
    dout_width = din_width
    din_point = din_width-1
    dout_point = dout_width-1

    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    fft_size = 1024.

    #initialize signals
    dut.next.value =0
    dut.X0_re.value = 0;    dut.X0_im.value = 0
    dut.X1_re.value = 0;    dut.X1_im.value = 0
    dut.X2_re.value = 0;    dut.X2_im.value = 0
    dut.X3_re.value = 0;    dut.X3_im.value = 0
    dut.X4_re.value = 0;    dut.X4_im.value = 0
    dut.X5_re.value = 0;    dut.X5_im.value = 0
    dut.X6_re.value = 0;    dut.X6_im.value = 0
    dut.X7_re.value = 0;    dut.X7_im.value = 0
    #
    dut.reset.value = 1
    await ClockCycles(dut.clk, 3)
    dut.reset.value= 0
    await ClockCycles(dut.clk,1)
    await sweep_test(dut,int(fft_size), din_width, din_point)

    


async def sweep_test(dut, fft_len, din_width, din_point):
    """Input a sweep
    """
    dout_width = din_width
    dout_point = din_point
    data = np.zeros([fft_len, fft_len], dtype=complex)
    t = np.arange(fft_len)
    for i in range(fft_len):
        data[:,i] = 0.8*np.exp(1j*2*np.pi*t*i/fft_len)
    data = data.flatten()
    re = two_comp_pack(data.real, din_width, din_point)
    im = two_comp_pack(data.imag, din_width, din_point)
    dat = re+1j*im
    cocotb.fork(write_data(dut, dat))
    
    dout = await read_data(dut, fft_len**2//8,fft_len,dout_width, dout_point)
    np.savetxt('dout_data.txt',dout)
    plt.imshow(20*np.log10(np.abs(dout)+1))
    plt.show()





async def write_data(dut, data):
    dut.reset.value = 1
    await ClockCycles(dut.clk,1)
    dut.reset.value = 0
    await ClockCycles(dut.clk,1)
    dut.next.value = 1
    await ClockCycles(dut.clk,1)
    for i in range(len(data)//8):
        dut.next.value = 0
        dut.X0_re.value = int(data[8*i].real)
        dut.X0_im.value = int(data[8*i].imag)
        dut.X1_re.value = int(data[8*i+1].real)
        dut.X1_im.value = int(data[8*i+1].imag)
        dut.X2_re.value = int(data[8*i+2].real)
        dut.X2_im.value = int(data[8*i+2].imag)
        dut.X3_re.value = int(data[8*i+3].real)
        dut.X3_im.value = int(data[8*i+3].imag)
        dut.X4_re.value = int(data[8*i+4].real)
        dut.X4_im.value = int(data[8*i+4].imag)
        dut.X5_re.value = int(data[8*i+5].real)
        dut.X5_im.value = int(data[8*i+5].imag)
        dut.X6_re.value = int(data[8*i+6].real)
        dut.X6_im.value = int(data[8*i+6].imag)
        dut.X7_re.value = int(data[8*i+7].real)
        dut.X7_im.value = int(data[8*i+7].imag)
        await ClockCycles(dut.clk,1)



async def read_data(dut, iters,fft_size, dout_width, dout_point):
    """
    Read the fft output and collect the data
    """
    await RisingEdge(dut.next_out)
    await ClockCycles(dut.clk, 2)
    data = np.zeros([iters, 8], dtype=complex)
    for i in range(iters):
        print(i)
        y0_re = int(dut.Y0_re.value);    y0_im = int(dut.Y0_im.value)
        y1_re = int(dut.Y1_re.value);    y1_im = int(dut.Y1_im.value)
        y2_re = int(dut.Y2_re.value);    y2_im = int(dut.Y2_im.value)
        y3_re = int(dut.Y3_re.value);    y3_im = int(dut.Y3_im.value)
        y4_re = int(dut.Y4_re.value);    y4_im = int(dut.Y4_im.value)
        y5_re = int(dut.Y4_re.value);    y5_im = int(dut.Y4_im.value)
        y6_re = int(dut.Y4_re.value);    y6_im = int(dut.Y4_im.value)
        y7_re = int(dut.Y4_re.value);    y7_im = int(dut.Y4_im.value)
        dout = np.array([y0_re,y0_im, y1_re,y1_im, y2_re,y2_im,
                         y3_re,y3_im, y4_re,y4_im, y5_re,y5_im,
                         y6_re,y6_im, y7_re,y7_im])
        dout = two_comp_unpack(dout, dout_width, dout_point)
        data[i,:] = dout[::2]+1j*dout[1::2]
        await ClockCycles(dut.clk,1)
    data = data.reshape([-1, fft_size])
    return data

