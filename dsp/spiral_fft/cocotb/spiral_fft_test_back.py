import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
from scipy.fftpack import fft
import matplotlib.pyplot as plt
from scipy.signal import gaussian, triang
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple

@cocotb.test()
async def spiral_fft_test(dut, iters=1, din_width=16,dout_width=16, thresh=0.15,
        freq=14, phase=0):
    np.random.seed(19)
    din_pt = din_width-1
    dout_pt = dout_width-1

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

    #sinewaves
    """
    #random generated
    gold = np.zeros([iters,1024], dtype=complex)
    din_b = np.zeros([iters, 1024], dtype=complex)
    for i in range(iters):
        freq = np.random.randint(1024)
        print(freq)
        phase = np.pi*(np.random.random()-0.5)
        input_data = 0.8*np.exp(1j*2*np.pi*freq/fft_size*np.arange(fft_size)+np.deg2rad(phase))

        gold[i,:] = fft(input_data)/1024.
        din_re = two_comp_pack(np.array(input_data.real), din_width, din_pt)
        din_im = two_comp_pack(np.array(input_data.imag), din_width, din_pt)
        din_b[i,:] = din_re+1j*din_im
    gold = gold.reshape([-1,8])
    din_b = din_b.flatten()
    print(din_b[:10])

    #determined input
    input_data = 0.8*np.exp(1j*2*np.pi*freq/fft_size*np.arange(fft_size)+np.deg2rad(phase))

    gold = fft(input_data)/1024
    gold = np.vstack([gold, gold,gold])
    gold = gold.reshape([-1,8])

    din_re = two_comp_pack(np.array(input_data.real), din_width, din_pt)
    din_im = two_comp_pack(np.array(input_data.imag), din_width, din_pt)
    din_b = din_re+1j*din_im
    din_b = np.hstack([din_b,din_b,din_b])
    """
    
    #input_data = 0.8*gaussian(1024, std=100)
    #input_data = 0.8*triang(1024)
    input_data = 0.8*np.exp(1j*2*np.pi*np.arange(1024)*180/1024.)
    #input_data = np.zeros(1024, dtype=complex)
    #input_data[512-200:512+200] = 0.8


    gold = fft(input_data)/1024
    gold = np.vstack([gold, gold,gold])
    gold = gold.reshape([-1,8])

    din_re = two_comp_pack(np.array(input_data.real), din_width, din_pt)
    din_im = two_comp_pack(np.array(input_data.imag), din_width, din_pt)
    din_b = din_re+1j*din_im
    din_b = np.hstack([din_b,din_b,din_b])

    cocotb.fork(write_data(dut, din_b))
    dout_data = await cocotb.fork(read_data(dut,512, gold, dout_width, dout_pt, thresh))
    np.savetxt('dout_data.txt',dout_data)



async def write_data(dut, data):
    dut.reset.value = 1
    await ClockCycles(dut.clk,1)
    dut.reset.value =0
    await ClockCycles(dut.clk,1)
    dut.next.value = 1
    await ClockCycles(dut.clk,1)
    while(1):
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

        


async def read_data(dut,iters, gold, dout_width, dout_pt, thresh):
    await RisingEdge(dut.next_out)
    await ClockCycles(dut.clk, 2)
    data = np.zeros([iters,8], dtype=complex)
    #for i in range(gold.shape[0]):
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
        dout = two_comp_unpack(dout, dout_width, dout_pt)
        """
        for j in range(8):
            channel = (8*(i%128)+j)
            print("chann:%i \t gold: %.2f+%.2f j \t rtl:%.2f+%.2f j" 
                    %(channel, gold[i,j].real, gold[i,j].imag, dout[2*j], dout[2*j+1]))
            if(channel!=1023):
                #it seems that the last channel generate problems
                assert (np.abs(gold[i,j].real-dout[2*j])<thresh), ("Error real: Y%i" %j)
                assert (np.abs(gold[i,j].imag-dout[2*j+1])<thresh), ("Error imag: Y%i"%j)
        """
        data[i,:] = dout[::2]+1j*dout[1::2]
        await ClockCycles(dut.clk,1)
    return data

