import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
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
async def mandelbrot_line_test(dut, iters=50, pxl_iters=128, din_pt=12):
    width = 32
    height = 4  #16/4
    x_pos = -1
    y_pos = -1
    c = 0.5+0.2j
    step = 0.05
    ###
    c_re, c_im, step_bin, x0, y0 = two_comp.two_comp_pack(np.array([c.real, c.imag, step,x_pos,y_pos]), 32, din_pt)
    din_int = 32-din_pt
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.x_i<=int(x0); dut.y_i <=int(y0);
    dut.x_step <= int(step_bin)
    dut.y_step <= int(step_bin)
    dut.c_re <=int(c_re);
    dut.c_im <=int(c_im);
    dut.iters <= pxl_iters
    dut.rst <=0;
    dut.cx <=0
    dut.cy <=0
    await ClockCycles(dut.clk, 5)
    dut.rst <= 1
    await ClockCycles(dut.clk, 1)
    dut.rst <=0;
    await RisingEdge(dut.line_rdy)
    #await ClockCycles(dut.clk, 1024*5)
    y=0;
    step = int(step*2**din_pt)/2.**din_pt
    x_pos = int(x_pos*2**din_pt)/2.**din_pt
    y_pos = int(y_pos*2**din_pt)/2.**din_pt
    count =0
    for i in range(height):
        dut.cy <= 4*i
        for j in range(width):
            dut.cx <= j
            await ClockCycles(dut.clk,1)
            x = int((x_pos+j*step)*2**din_pt)/2.**din_pt
            y = int((y_pos+i*4*step)*2**din_pt)/2.**din_pt
            #pt = (x_pos+j*step)+1j*(y_pos+i*4*step)
            pt = x+1j*y
            gold = gold_pxl(pt,c, iters, din_int)
            out = dut.dout.value
            print("%i x,y:(%.4f %.4f)\t gold: %i \t rtl: %i" %(count,pt.real,pt.imag,gold, out))
            count +=1
    
