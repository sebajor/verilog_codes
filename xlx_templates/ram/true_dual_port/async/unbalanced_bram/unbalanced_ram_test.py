import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, Timer, FallingEdge
from cocotb.clock import Clock
import numpy as np
import sys
sys.path.append("../../../../../cocotb_python/")
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple

CLK_A = 8
CLK_B = 10

def setup_dut(dut):
    cocotb.fork(Clock(dut.clka, CLK_A, units='ns').start())
    fpga_clk = Clock(dut.clkb, CLK_B, units='ns')
    cocotb.fork(fpga_clk.start())
    dut.addra.value =0
    dut.dina.value =0
    dut.wea.value =0
    dut.ena.value =1
    dut.rsta.value =0
    dut.addrb.value =0
    dut.dinb.value =0
    dut.web.value =0
    dut.enb.value =1
    dut.rstb.value =0
    return 1

@cocotb.test()
async def unbalanced_ram_test(dut, mux_lat=0, deinterleave=2, nbits=32):
    size = 1024
    setup_dut(dut)
    
    await Timer(5*CLK_A, units='ns')
    await RisingEdge(dut.clka)
    #dat_a = np.arange(1024).reshape([-1, deinterleave])
    np.random.seed(10)
    dat_a = np.random.randint(nbits, size=size).reshape([-1, deinterleave])
    gold_a = dat_a.flatten()
    addr_a = np.arange(size//deinterleave)

    print('Write a')
    await write_a(dut, dat_a, addr_a, deinterleave, nbits)
    ClockCycles(dut.clka, 3)
    print('Read a')
    rdata = await read_a(dut, addr_a, deinterleave, nbits)
    rdata = rdata.flatten()
    for i in range(len(dat_a)):
        assert (rdata[i] == gold_a[i])

    await RisingEdge(dut.clkb)
    print("Read b")
    addrb = np.arange(size)
    rdata = await read_b(dut, addrb)
    for (rdat, dat) in zip(rdata, gold_a):
        assert (rdat==dat)

    print("Write b")
    dat_b = np.random.randint(nbits, size=size)
    await write_b(dut, dat_b, addrb)
    print("Read b")
    rdata = await read_b(dut, addrb)
    for (rdat, dat) in zip(rdata, dat_b):
        assert (rdat==dat)

    await RisingEdge(dut.clka)
    print("Read a")
    rdata = await read_a(dut, addr_a, deinterleave, nbits)
    rdata = rdata.flatten()
    for i in range(len(dat_b)):
        assert (rdata[i] == dat_b[i])









async def write_a(dut, data, addr, deinterleave, nbits):
    for i in range(len(addr)):
        dat = pack_multiple(data[i,:], deinterleave, nbits)
        dut.addra.value = int(addr[i])
        dut.dina.value = dat
        dut.wea.value =1 
        await ClockCycles(dut.clka,1)
    dut.wea.value = 0


async def read_a(dut, addr, deinterleave, nbits):
    out = np.zeros([len(addr)+1, deinterleave])
    for i in range(len(addr)):
        dut.addra.value = int(addr[i])
        dut.wea.value = 0
        await ClockCycles(dut.clka, 1)
        dout = int(dut.douta.value)
        out[i,:] = unpack_multiple(dout, deinterleave, nbits)
    await ClockCycles(dut.clka,1)
    dout = int(dut.douta.value)
    out[-1,:] = unpack_multiple(dout, deinterleave, nbits)
    return out[1:,:]

async def write_b(dut, data, addrs):
    for addr, dat in zip(addrs, data):
        dut.addrb.value = int(addr)
        dut.dinb.value = int(dat)
        dut.web.value =1 
        await ClockCycles(dut.clkb, 1)
    dut.web.value = 0

async def read_b(dut, addr):
    out = np.zeros(len(addr)+1)
    for i in range(len(addr)):
        dut.addrb.value = int(addr[i])
        dut.web.value = 0
        await ClockCycles(dut.clkb, 1)
        dout = int(dut.doutb.value)
        out[i] = dout
    await ClockCycles(dut.clkb,1)
    dout = int(dut.doutb.value)
    out[-1] = dout    
    return out[1:]


