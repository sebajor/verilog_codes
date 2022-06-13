import cocotb, sys
import numpy as np
import matplotlib.pyplot as plt
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
sys.path.append('../../../cocotb_python')
import two_comp

def gold_pxl(val, c, pxl_iters, din_int):
    max_val = 2**din_int-1
    counter =0
    tmp = np.copy(val)
    for i in range(pxl_iters):
        if((tmp.real>max_val) or (tmp.imag>max_val)):
            break
        else:
            tmp = tmp**2+c
            counter +=1
    return counter
        

@cocotb.test()
async def mandelbrot_pxl_test(dut, iters=50, pxl_iters=128, din_pt=12):
    c = 0.5+0.2j
    din_int = 32-din_pt
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.x_init.value=0; dut.y_init .value=0;
    c_re = two_comp.two_comp_pack(np.array([c.real]), 32, din_pt)
    c_im = two_comp.two_comp_pack(np.array([c.imag]), 32, din_pt)
    dut.c_re.value=int(c_re);  
    dut.c_im.value=int(c_im);
    dut.iters.value= pxl_iters
    dut.din_valid .value=0;
    await ClockCycles(dut.clk, 1)
    np.random.seed(30)
    #din_val_re = 2*(np.random.random(iters)-0.5)
    #din_val_im = 2*(np.random.random(iters)-0.5)
    #din_val_re = np.linspace(-1, 1, iters)
    #din_val_im = np.linspace(-1, 1, iters)
    din_val_re = np.ones(iters)*-0.15
    din_val_im = np.ones(iters)*-0.6
    din_re = two_comp.two_comp_pack(din_val_re, 32, din_pt)
    din_im = two_comp.two_comp_pack(din_val_im, 32, din_pt)
    for i in range(iters):
        dut.din_valid .value=1
        dut.x_init.value= int(din_re[i])
        dut.y_init.value= int(din_im[i])
        #dut.c_re.value= int(din_re[i])
        #dut.c_im.value= int(din_im[i])
        dut.c_im.value= int(c_im)
        dut.c_re.value= int(c_re)
        await ClockCycles(dut.clk,1)
        dut.din_valid .value=0;
        await RisingEdge(dut.dout_valid)
        gold = gold_pxl(din_val_re[i]+1j*din_val_im[i], c,pxl_iters, din_int)
        #gold = gold_pxl(din_val_re[i]+1j*din_val_im[i], din_val_re[i]+1j*din_val_im[i],pxl_iters, din_int)
        rtl_out = int(dut.dout.value)
        print("%.4f, %.4f"%(din_val_re[i], din_val_im[i]))
        print('gold:%i \t rtl:%i' %(gold, rtl_out))
    x0=-2; y0=-2; x_size=200; y_size=200; step=4./x_size
    await mandelbrot_image(dut, x0,y0,step,x_size, y_size, din_pt)


async def mandelbrot_image(dut,x0, y0, step, x_size=200, y_size=200, din_pt=12):
    #x_i, y_i, step_b = two_comp.two_comp_pack(np.array([x0,y0,step]), 32, din_pt)
    data = np.zeros([x_size, y_size])
    for i in range(y_size):
        y_pos = y0+i*step
        y_pos = two_comp.two_comp_pack(np.array([y_pos]), 32,din_pt)
        for j in range(x_size):
            x_pos = x0+j*step
            x_pos = two_comp.two_comp_pack(np.array([x_pos]),32,din_pt)
            dut.x_init.value= int(x_pos)
            dut.y_init.value= int(y_pos)
            dut.c_re.value= int(x_pos)
            dut.c_im.value= int(y_pos)
            dut.din_valid.value= 1
            await ClockCycles(dut.clk,1)
            dut.din_valid.value=0
            await RisingEdge(dut.dout_valid)
            rtl_out = int(dut.dout.value)
            data[j,i] = rtl_out
    plt.imshow(data)
    plt.savefig('ex.png')
    #np.savetxt('data',data)
    return 1


    

