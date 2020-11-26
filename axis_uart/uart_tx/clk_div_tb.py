#!/usr/bin python3

import os
from myhdl import Cosimulation, Simulation, delay, Signal, intbv, always

def clk_driver(clk, period=4):
    @always(delay(period//2))
    def driver():
        clk.next = ~clk;
    return driver


def clk_div_tb(clk_in, clk_out):
    div = 16
    os.system('iverilog -o clk_div_tb clock_divider.v clock_div_tb.v')
    return Cosimulation('vvp -m ./myhdl.vpi clk_div_tb', clk_in=clk_in, clk_out=clk_out)


clk_in = Signal(0)
clk_out = Signal(intbv(0))

clk_inst = clk_driver(clk_in)
clk_div_inst = clk_div_tb(clk_in, clk_out)
sim = Simulation(clk_inst, clk_div_inst)
sim.run(100)
