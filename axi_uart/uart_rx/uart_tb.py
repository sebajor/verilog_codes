#!/usr/bin python3

import os
import numpy as np
from myhdl import Cosimulation, Simulation, Signal, delay, always, intbv, now


def clk_driver(clk, period=4):
    @always(delay(period//2))
    def driver():
        clk.next = ~clk
    return driver

def uart_rx(clk, rst, tx_data, data, valid):
    os.system('iverilog -o uart_tb uart_rx.v uart_tb.v')
    return Cosimulation('vvp -m ./myhdl.vpi uart_tb', clk=clk, rst=rst, tx_data=tx_data,data=data, valid=valid)

def evol_tx(tx_data, msg=0xAB, period=4):
    @always(delay(period*217))    
    def driven():
        tx_data.next = ~tx_data
    return driven

def check(data,valid):
    @always(valid.posedge)
    def check():
        print('valid: ', valid, 'data: ',data)
    return check


clk = Signal(0)
rst = Signal(0)
tx_data = Signal(1)
data = Signal(intbv(0)[7:])
valid = Signal(intbv(0)[4:])

clk_inst =clk_driver(clk)
uart_inst = uart_rx(clk,rst,tx_data, data, valid)
tx_inst = evol_tx(tx_data)
check_inst = check(data, valid)

sim = Simulation(clk_inst, uart_inst, tx_inst, check_inst)
sim.run(9000)






        
    

