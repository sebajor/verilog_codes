import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer
import sys
sys.path.append("../../../../cocotb_python")
from two_comp import two_comp_pack, two_comp_unpack, two_pack_multiple
import queue


class python_r22sdf_bf2():
    def __init__(self, stage_size):
        self.stage_size = stage_size
        self.feedback = queue.Queue()
        for i in range(stage_size):
            self.feedback.put(0)
        self.dout = 0
        self.delay_input = 0
        self.delay_output = 0
        self.control0 = 0 
        self.counter0 = -1
        self.control1 = 0 
        self.counter1 = -1


    def insert_data(self, data):
        #Not sure at all about this controlling signals!!!
        ##for what I got the control0 is in charge of swapping the outputs and it should
        ##flip every N/2, the control1 signal is in charge of the -j multiplication
        ##and should be 1 only in the interval (3N/4, N)..
        ##This is considering that the DFT is N size, and that means that hte BF1 
        ##has a N/2 delay line and then the BF2 has a delay line of N/4
        if(self.counter0==(self.stage_size-1)): ##CHECK!
            self.control0 = not(self.control0)
            self.counter0 = 0
        else:
            self.counter0+=1
        
        if(self.counter1==(3*self.stage_size-1)):
            self.control1 = 1
            self.counter1+=1
        if(self.counter1==(4*self.stage_size)):
            self.control1 = 0
            self.counter1=0
        else:
            self.counter1+=1

        self.delay_output = self.feedback.get()
        if(self.control0):
            ##here is where the shit becomes real D:
            if(self.control1):
                self.dout = self.delay_output+data
                self.delay_input = self.delay_output-data
            else:
                self.dout = self.delay_output+data*-1j
                self.delay_input = self.delay_output-(data*-1j)
        else:
            self.dout = self.delay_output
            self.delay_input = data
        self.feedback.put(self.delay_input)
    


