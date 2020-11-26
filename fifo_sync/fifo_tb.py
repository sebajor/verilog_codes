#!/usr/bin python3
import os
from myhdl import Cosimulation, Simulation, Signal, delay, always, intbv, instance

def clk_driven(aclk, period=2):
    @always(delay(period//2))
    def driven():
        aclk.next = ~aclk
    return driven

def tb(aclk, arstn, in_data_tdata, in_data_tvalid, out_data_tready,
        in_data_tready, out_data_tdata, out_data_tvalid, full, empty):
    os.system('iverilog -o fifo_tb fifo_sync.v fifo_tb.v ')
    return Cosimulation('vvp -m ../../myhdl.vpi fifo_tb', aclk=aclk,
                        arstn=arstn, in_data_tdata=in_data_tdata, 
                        in_data_tvalid=in_data_tvalid, 
                        out_data_tready=out_data_tready, in_data_tready= in_data_tready, 
                        out_data_tdata=out_data_tdata, out_data_tvalid=out_data_tvalid,
                        full=full, empty=empty)


def evol(aclk, arstn, in_data_tdata, in_data_tvalid, out_data_tready, period=2):
    @instance
    def evol_data():
        yield(delay(period//2))
        yield(delay(period*2))
        arstn.next = 1
        in_data_tvalid.next = 0
        yield(delay(period*3))
        arstn.next =0
        yield(delay(period*3))
        arstn.next = 1
        #in_data_tvalid.next = 1
        #in_data_tdata.next = 129
        yield(delay(period*10))
        for i in range(99):
            in_data_tdata.next = i
            if(i%3==0):
                in_data_tvalid.next = 1
            else:
                in_data_tvalid.next = 0
            yield(delay(period))

        out_data_tready.next = 1
        for i in range(99):
            in_data_tdata.next = i
            if(i%3==0):
                in_data_tvalid.next = 1
            else:
                in_data_tvalid.next = 0
            yield(delay(period))
        arstn.next = 0
        yield(delay(3*period))
        arstn.next = 1
        yield(delay(period))
        """
        for i in range(100):
            if(i==80):
                out_data_tready.next = 1
            in_data_tdata.next = i
            yield(delay(period))
        in_data_tvalid.next = 0
        yield(delay(period*40))
        out_data_tready.next =0
        yield(delay(period*20))
        out_data_tready.next = 1
        """
        """
        yield(delay(period*60))
        in_data_tdata.next = 400
        in_data_tvalid.next = 1
        yield(delay(period))
        in_data_tvalid.next =0
        yield(delay(period))
        """
        """test2
        for i in  range(60):
            if(i%3==0):
                out_data_tready.next = 1
            else:
                out_data_tready.next = 0
                in_data_tvalid.next = 0
            if(i==40):
                in_data_tdata.next = 30
                in_data_tvalid.next = 1
            yield(delay(period))
        """
        """ test1
        for i in range(40):
            out_data_tready.next = 1
            if(i%4==0):
                in_data_tvalid.next = 1
                in_data_tdata.next = 100
            else:
                in_data_tdata.next = 5
                in_data_tvalid.next = 0
            yield(delay(period))
        yield(delay(period*20))
        in_data_tdata.next = 15
        in_data_tvalid.next = 1
        yield(delay(period))
        in_data_tvalid.next = 0
        out_data_tready.next = 0
        yield(delay(period*10))
        for i in range(20):
            in_data_tdata.next = i
            in_data_tvalid.next = 1
            if(i%3==0):
                out_data_tready.next = 1
            else:
                out_data_tready.next = 0
            yield(delay(period))
           """ 
    return evol_data



aclk=Signal(0)
arstn=Signal(0)
in_data_tdata=Signal(0)
in_data_tvalid = Signal(1)
out_data_tready=Signal(0)

in_data_tready = Signal(intbv(0))
out_data_tdata = Signal(intbv(0)[32:])
out_data_tvalid = Signal(intbv(0))
full = Signal(intbv(0))
empty = Signal(intbv(0))

clk_inst = clk_driven(aclk)
tb_inst= tb(aclk, arstn, in_data_tdata, in_data_tvalid, out_data_tready, in_data_tready, out_data_tdata, out_data_tvalid, full, empty)
evol_inst = evol(aclk=aclk, arstn=arstn, in_data_tdata=in_data_tdata, in_data_tvalid=in_data_tvalid, out_data_tready=out_data_tready)

sim = Simulation(clk_inst, tb_inst, evol_inst)
sim.run(600)


