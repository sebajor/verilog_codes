import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock
import numpy as np

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

def pack_multiple(data, mult_factor, nbits):
    """Concatenate data in a single number
        data: data to concatenate
        mult_factor: factor to interleave
        nbits:  the number of bits to represent the signal
    """
    out = 0
    for i in range(mult_factor):
        out += int(data[i])<<(i*nbits)
    return out


def unpack_multiple(data, mult_factor, nbits):
    """To separate interleaved data
        data: interleaved data
        mult_factor: interleave factor
        nbits:
    """
    out = np.zeros(mult_factor)
    for i in range(mult_factor):
        aux = int(data>>(nbits*i))
        mask = 2**nbits-1
        dat = aux & mask
        out[i] = dat
    return out


@cocotb.test()
async def unbalanced_ram_test(dut, mux_lat=0,deinterleave=2, nbits=32):
    setup_dut(dut)

    lat_b = 5

    await Timer(5*CLK_A, units='ns')
    await RisingEdge(dut.clka)
    dat_a = np.arange(1024).reshape([-1,deinterleave])
    addr_a = np.arange(1024//deinterleave)

    print('Write a')
    await write_a(dut, dat_a, addr_a, deinterleave, nbits,1)
    ClockCycles(dut.clka, 10)
    dato_a = await read_a(dut, addr_a, deinterleave, nbits,2)
    dato_a = dato_a.flatten()
    print('Read a')
    for i in range(len(dat_a)):
        assert (dato_a[i] == i)
    
    await RisingEdge(dut.clkb)
    addrb = np.arange(1024)
    dato_b = await read_b(dut, addrb,lat_b)
    print('Read b')
    for i in range(len(dato_b)):
        assert (dato_b[i] == i)

    
    await RisingEdge(dut.clkb)
    print('Write b')
    dat_b = np.arange(1023,-1,-1)
    ##b channel write at the bottom the bigger one, so we order them to have the lower one first
    datb = dat_b.reshape([-1,2])[:,::-1].flatten()
    addrb = np.arange(1024)
    await write_b(dut, dat_b, addrb, deinterleave)
    ClockCycles(dut.clka, 10)

    print('Read b')
    dato_b = await read_b(dut, addrb,lat_b)
    for i in range(len(dato_b)):
        assert (dato_b[i] == dat_b[i])
    
    print('Read a')
    await RisingEdge(dut.clka)

    dato_a = await read_a(dut, addr_a, deinterleave, nbits,2)
    dato_a = dato_a.flatten()
    for i in range(len(dat_a)):
        assert (dato_a[i] == dat_b[i])

    #cont
    cocotb.fork(cont_addr_b(dut, addrb))
    await read_cont_b(dut, dat_b)
    await ClockCycles(dut.clkb, 10)


async def write_a(dut, data, addr, deinterleave, nbits, lat):
    for i in range(len(addr)):
        dat = pack_multiple(data[i,:], deinterleave, nbits)
        dut.addra.value = int(addr[i])
        dut.dina.value = dat
        dut.wea.value = 1
        await ClockCycles(dut.clka, lat)
    dut.wea.value = 0


async def read_a(dut, addr, deinterleave, nbits,lat):
    out = np.zeros([len(addr), deinterleave])
    for i in range(len(addr)):
        dut.addra.value = int(addr[i])
        dut.wea.value = 0
        await ClockCycles(dut.clka,lat)
        dout = int(dut.douta.value)
        out[i,:] = unpack_multiple(dout, deinterleave, nbits)
    return out
       

async def write_b(dut, data, addr, deinterleave):
    count =1
    for i in range(len(addr)):
        dut.addrb.value = int(addr[i])
        dut.dinb.value = int(data[i])
        if(count == deinterleave):
            dut.web.value = 1#int(count)
            count =1
        else:
            dut.web.value = 0#int(count)
        await ClockCycles(dut.clkb, 1)
        count +=1
    dut.web.value = 0
    

async def read_b(dut, addr, lat):
    out = np.zeros(len(addr))
    for i in range(len(addr)):
        dut.addrb.value = int(addr[i])
        dut.web.value = 0
        dut.in_valid_b.value = 1
        await ClockCycles(dut.clkb,lat)
        dout = int(dut.doutb.value)
        out[i] = dout
    dut.in_valid_b.value = 0
    return out

async def cont_addr_b(dut, addr):
    for i in range(len(addr)):
        dut.addrb.value = int(addr[i])
        dut.web.value = 0
        dut.in_valid_b.value = 1
        await ClockCycles(dut.clkb, 1)
    dut.in_valid_b.value = 0

async def read_cont_b(dut, data):
    count =0
    while(1):
        valid = dut.out_valid_b.value
        if(valid):
            out = int(dut.doutb.value)
            print(out)
            #assert (data[count] == out)
            count +=1
        await ClockCycles(dut.clkb, 1)
        if(count == (len(data)-1)):
            break

    
