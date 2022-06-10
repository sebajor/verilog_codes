import numpy as np
import matplotlib.pyplot as plt
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack
import cv2

###
### Author:Sebastian Jorquera
###

def conv_operation(img, kernel):
    out = np.zeros([img.shape[0]-kernel.shape[0]+1, img.shape[1]-kernel.shape[1]+1])
    for i in range(img.shape[0]-kernel.shape[0]+1):
        for j in range(img.shape[1]-kernel.shape[1]+1):
            aux = img[i:i+kernel.shape[0], j:j+kernel.shape[1]]*kernel
            out[i,j] = np.sum(aux)
    return out

@cocotb.test()
async def image_convolution_test(dut, file_in="../test_img.png", file_out='result.png',
        kernel='weight/y_sobel.txt', din_width=8, din_pt=0, dout_width=20,
        dout_pt=8, thresh=0.5):
    
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.din_valid.value = 0
    dut.din0.value = 0
    dut.din1.value = 0
    dut.din2.value = 0
    dut.din3.value = 0
    dut.din4.value = 0
    dut.din5.value = 0
    dut.din6.value = 0
    dut.din7.value = 0
    dut.din8.value = 0
    
    await ClockCycles(dut.clk, 4)
    
    img = cv2.imread(file_in)[:,:,0] #just one channel 
    kern = np.loadtxt(kernel)
    kern = kern.reshape([3,3])
    gold = conv_operation(img, kern)
    gold_shape = gold.shape

    gold = gold.flatten()
    din = img.flatten()
    din_b = two_comp_pack(din, din_width, din_pt)
    din_b = din_b.reshape(img.shape)
    cocotb.fork(write_data(dut, din_b))
    result = await read_data(dut, gold, dout_width, dout_pt, thresh)

    result = result.reshape(gold_shape)
    
    fig = plt.figure()
    ax1 = fig.add_subplot(121)
    ax2 = fig.add_subplot(122)
    ax1.imshow(gold.reshape(gold_shape), cmap='gray')
    ax1.set_title('Golden model')
    ax2.imshow(result, cmap='gray')
    ax2.set_title('rtl')
    fig.tight_layout()
    plt.savefig(file_out)
    plt.close()


async def write_data(dut, data, kern=3):
    for i in range(data.shape[0]-kern+1):
        for j in range(data.shape[1]-kern+1):
            dut.din0.value = int(data[i , j  ])
            dut.din1.value = int(data[i+1,j  ])
            dut.din2.value = int(data[i+2,j  ])
            dut.din3.value = int(data[i  ,j+1])
            dut.din4.value = int(data[i+1,j+1])
            dut.din5.value = int(data[i+2,j+1])
            dut.din6.value = int(data[i , j+2])
            dut.din7.value = int(data[i+1,j+2])
            dut.din8.value = int(data[i+2,j+2])
            dut.din_valid.value =1
            await ClockCycles(dut.clk,1)
    dut.din_valid.value =0

async def read_data(dut, gold, dout_width, dout_pt, thresh):
    count = 0
    result = np.zeros(len(gold))
    while(count<len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            dout = two_comp_unpack(np.array(dout), dout_width, dout_pt)
            print("%.2f \t gold:%.2f \t rtl:%.2f" %(count/len(gold), gold[count], dout))
            assert (np.abs(dout-gold[count])<thresh ), "Error"
            result[count] = dout
            count +=1
        await ClockCycles(dut.clk, 1)
    return result

