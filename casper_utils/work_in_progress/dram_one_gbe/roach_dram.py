import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
import numpy as np
import queue, copy
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple

class roach_dram():

    def __init__(self,dut, addr, init_mem=None):
        """
        """
        if(init_mem is not None):
            self.mem = init_mem
        else:
            self.mem = np.zeros([2**addr])
        self.prev_val = np.zeros(3)
        self.read_req = 0
        self.read_addr = []
        self.dut = dut

    async def dram_behaviour(self, dut, iters, burst_count=60, wait=10):
        """When there is a read request we wait burst_count cycles
        to review it. Then we could decide if its a burst or just a
        beat transaction.
        That also mean that we cant have a burst bigger than burst_count
        """
        burst_counter=0
        for i in range(iters):
            self.prev_val = np.roll(self.prev_val, 1)
            self.prev_val[0] = int(self.dut.cmd_valid.value)
            rwn = int(self.dut.rwn.value)
            if(rwn):
                await self.read_mode()
            else:
                await self.write_mode()
            ##need to see if the request is a burst or just beat...
            if(self.read_req!=0):
                burst_counter+=1
                if(burst_counter==(2*burst_count)):
                    addrs = self.read_addr.copy()
                    cocotb.fork(self.read_response(wait, addrs))
                    burst_counter=0
                    self.read_req=0
                    self.read_addr.clear()
            await ClockCycles(self.dut.clk, 1)
            


    async def read_mode(self):
        """
        """
        toggle = self.prev_val.astype(bool)
        #if((not toggle[0]) and (toggle[1]) and (not toggle[2])):
            ##detect toggle and not just a rising/falling edge
        if((toggle[0]) and (not toggle[1])):
            #detect rising edge
            self.read_req += 1
            addr = int(self.dut.dram_addr.value)
            self.read_addr.append(addr)
        return 1
        
    async def read_response(self, wait, addrs):
        """wait is the maximum cycles that we could wait to respond a request
        """
        addrs.reverse()
        wait_val = np.random.randint(wait)
        self.dut.rd_valid.value = 0
        await ClockCycles(self.dut.clk,wait_val)
        self.dut.rd_valid.value = 1
        while(len(addrs)!=0):
            addr = addrs.pop()
            data = self.mem[addr]
            self.dut.dram_data.value = int(data)
            await ClockCycles(self.dut.clk, 2)
        self.dut.rd_valid.value = 0

            

    async def write_mode(self):
        #TODO
        return 1

