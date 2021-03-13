#!/usr/bin python3

import os
import numpy as np
from myhdl import Cosimulation, Simulation, Signal, delay, always, intbv, now

def clk_driver(clk, period=4):
    @always(delay(period//4))
    def driver():
        clk.next = ~clk
    return driver


def uart_tx_tb(axis_tdata, axis_tready, axis_tvalid, clk,tx_data):
    os.system('iverilog -o uart_tb uart_tx.v uart_tx_tb.v')
    return Cosimulation('vvp -m ./myhdl.vpi uart_tb', axis_tdata=axis_tdata, axis_tready=axis_tready, axis_tvalid=axis_tvalid, clk=clk, tx_data=tx_data)



def check(tx_data):
    @always(delay(period*217))
    def check():
        print('tx_value: ', tx_data)
    return check

def valid(axis_tvalid):
    @always(delay(4*800))
    def driver():
        axis_tvalid.next = ~axis_tvalid
    return driver

axis_tdata = Signal(0x41)
axis_tvalid = Signal(0)
clk = Signal(0)
axis_tready = Signal(intbv(0));
tx_data = Signal(0)

clk_inst = clk_driver(clk)
uart_inst = uart_tx_tb(axis_tdata, axis_tready, axis_tvalid, clk, tx_data)
valid_inst = valid(axis_tvalid) 

sim = Simulation(clk_inst, uart_inst, valid_inst)
sim.run(9000)
