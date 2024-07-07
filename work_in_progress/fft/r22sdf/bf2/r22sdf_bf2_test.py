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
        elif(self.counter1==(4*self.stage_size-1)):
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
                self.dout = self.delay_output+(data*-1j)
                self.delay_input = self.delay_output-(data*-1j)
        else:
            self.dout = self.delay_output
            self.delay_input = data
        self.feedback.put(self.delay_input)
    
@cocotb.test()
async def r22sdf_bf2_test(dut, iters=128, thresh=1e-3):
    din_width = int(dut.DIN_WIDTH.value)
    din_point = int(dut.DIN_WIDTH.value)-1
    stage_size = int(dut.FEEDBACK_SIZE.value)
    dout_width = din_width+1    #not consider scaling down
    #initialize the signals
    clk = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clk.start())
    dut.control0.value = 0
    dut.control1.value = 0
    dut.din_re.value = 0
    dut.din_im.value = 0
    await ClockCycles(dut.clk, 5)

    data =((np.random.random(iters)-0.5)+(np.random.random(iters)-0.5)*1j)
    #data = np.ones(iters)*0.5*1j
    gold_model = python_r22sdf_bf2(stage_size)
    gold_dout = np.zeros(len(data), dtype=complex)
    for i,dat in enumerate(data):
        gold_model.insert_data(dat)
        gold_dout[i] = gold_model.dout
    dat_re = two_comp_pack(data.real, din_width, din_point)
    dat_im = two_comp_pack(data.imag, din_width, din_point)
    data_bin = [dat_re, dat_im]

    cocotb.start_soon(read_data(dut, gold_dout, dout_width, din_point, thresh))
    await write_data(dut, data_bin, stage_size)


async def write_data(dut, data, stage_size):
    """
    Write the input data and the control signal
    """
    dat_re = data[0]
    dat_im = data[1]
    counter0 = -1
    counter1 = -1
    for i in range(len(dat_re)):
        dut.din_re.value = int(dat_re[i])
        dut.din_im.value = int(dat_im[i])
        if(counter0==(stage_size-1)):  #CHECK!!!
            counter0 =0
            ctrl_val = bool(int(dut.control0.value))
            dut.control0.value = int(not ctrl_val)
        else:
            counter0+=1
        
        if(counter1==(3*stage_size-1)):
            dut.control1.value = 1
            counter1+=1
        elif(counter1==(4*stage_size-1)):
            dut.control1.value = 0
            counter1 =0
        else:
            counter1+=1
        await ClockCycles(dut.clk, 1)

async def read_data(dut, gold_dout, dout_width, dout_point, thresh):
    counter =0
    await ClockCycles(dut.clk,1)    ##the first cycle write the data
    while(counter<len(gold_dout)):
        out_re = int(dut.dout_re.value)
        out_im = int(dut.dout_im.value)
        out_rtl = two_comp_unpack(np.array([out_re, out_im]), dout_width, dout_point)
        print("%i rtl: %f+%f j \t python: %f+%f j"%(counter, out_rtl[0], out_rtl[1],
                                                 gold_dout[counter].real, gold_dout[counter].imag)
            )

        assert(np.abs(gold_dout[counter].real-out_rtl[0])<thresh)
        assert(np.abs(gold_dout[counter].imag-out_rtl[1])<thresh)
        await ClockCycles(dut.clk,1)
        counter +=1




