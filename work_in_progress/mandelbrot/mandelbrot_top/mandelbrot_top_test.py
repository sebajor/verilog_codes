import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
import two_comp

@cocotb.test()
async def mandelbrot_top_test(dut, iters=255, x_size=200, y_size=200, din_pt=20):
    x_pos = -0.8#-1.5
    y_pos = -0.2#-1.5
    c = 0.5+0.2j
    step = 0.4/200#3./200
    ###
    c_re, c_im, step_bin, x0, y0 = two_comp.two_comp_pack(np.array([c.real, c.imag, step,x_pos,y_pos]), 32, din_pt)
    din_int = 32-din_pt
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.x_i<=int(x0); dut.y_i <=int(y0);
    dut.x_step <= int(step_bin)
    dut.y_step <= int(step_bin)
    dut.c_re <=int(c_re);
    dut.c_im <=int(c_im);
    dut.iters <= int(iters)
    dut.rst <=0;
    dut.cx <=0
    dut.cy <=0
    await ClockCycles(dut.clk, 5)
    dut.rst <= 1
    await ClockCycles(dut.clk, 1)
    dut.rst <=0;
    await RisingEdge(dut.rdy)
    print('finish calculations')
    data = np.zeros([x_size, y_size])
    for i in range(y_size):
        dut.cy <= i
        for j in range(x_size):
            dut.cx <= j
            await ClockCycles(dut.clk,1)
            #pt = (x_pos+j*step)+1j*(y_pos+i*4*step)
            out = dut.dout.value
            data[j,i] = int(out)
            #print("%i x,y:(%.4f %.4f)\t gold: %i \t rtl: %i" %(count,pt.real,pt.imag,gold, out))
    np.savetxt('data',data)

