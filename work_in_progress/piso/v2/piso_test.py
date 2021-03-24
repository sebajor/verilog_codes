import cocotb, struct
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles


@cocotb.test()
async def piso_test(dut, iters=128, din_width=256, dout_width=64):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(10)
    dut.rst <= 0
    #din = np.random.randint(0, 2**(dout_width-1)-1, size=[4, iters])
    test1 = await basic_test(dut=dut, iters=iters, din_width=din_width, dout_width=dout_width)
    #test2 = await burst_test(dut=dut, iters=3*iters, burst_len=64, n_burst=2)
    #test3 = await burst_write_read(dut=dut, w_burst=513, r_burst=1024)


async def basic_test(dut, iters=128, din_width=256, dout_width=64):
    din = np.arange(4*iters)
    din = din.reshape([-1,4]).T
    din_val = BinaryValue()
    """
    din = np.zeros([4, iters])
    for i in range(iters):
        din[:,i] = np.arange(4)
    """
    dut.din_valid <=0
    dut.dout_ready <=0
    dut.din <= 0
    await ClockCycles(dut.clk, 2)
    out_val = []
    en_read = 0
    for i in range(iters):
        #dat = din[0,i]+din[1,i]*2**(dout_width)+din[2,i]*2**(2*dout_width)+din[3,i]*2**(3*dout_width)
        dat = struct.pack('>4Q',*(din[::-1,i].astype(int)))
        din_val.set_buff(dat)
        dut.din <= din_val
        dut.din_valid <= 1
        en_read = int(not(en_read))
        dut.dout_ready <= en_read
        await ClockCycles(dut.clk, 1)
        val = dut.dout_valid.value
        if(val):
            out = dut.dout.value
            out_val.append(out)
    gold_val = (din.T).flatten()
    for i in range(len(out_val)):
        #print("%x   %x" %(out_val[i+3], gold_val[i]))
        assert (int(gold_val[i])==int(out_val[i])), "fail in avg {}".format(i)


async def burst_test(dut, iters=300, burst_len=64, n_burst=3):
    din = np.arange(4*burst_len)
    din = din.reshape([-1,4]).T
    din_val = BinaryValue()
    """
    din = np.zeros([4, iters])
    for i in range(iters):
        din[:,i] = np.arange(4)
    """
    dut.din_valid <=0
    dut.dout_ready <=0
    dut.din <= 0
    await ClockCycles(dut.clk, 2)
    out_val = []
    for j in range(n_burst):
        for i in range(burst_len):
            #dat = din[0,i]+din[1,i]*2**(dout_width)+din[2,i]*2**(2*dout_width)+din[3,i]*2**(3*dout_width)
            dat = struct.pack('>4Q',*(din[::-1,i].astype(int)))
            din_val.set_buff(dat)
            dut.din <= din_val
            dut.din_valid <= 1
            dut.dout_ready <= 1
            await ClockCycles(dut.clk, 1)
            val = dut.dout_valid.value
            if(val):
                out = dut.dout.value
                out_val.append(out)
        dut.din_valid <=0
        for i in range(iters-burst_len):
            await ClockCycles(dut.clk, 1)
            val = dut.dout_valid.value
            if(val):
                out = dut.dout.value
                out_val.append(out)
    gold_val = (din.T).flatten()
    for i in range(len(out_val)):
        #print("out: %x   gold:%x" %(out_val[i], gold_val[i%(4*burst_len)]))
        assert (int(gold_val[i%(4*burst_len)])==int(out_val[i])), "fail in avg {}".format(i)

async def burst_write_read(dut, w_burst=513, r_burst=1024, stop_read=128, stop_write=4096, n_burst=3):
    din = np.arange(4*w_burst)
    din = din.reshape([-1,4]).T
    din_val = BinaryValue()
    """
    din = np.zeros([4, iters])
    for i in range(iters):
        din[:,i] = np.arange(4)
    """
    dut.din_valid <=0
    dut.dout_ready <=0
    dut.din <= 0
    await ClockCycles(dut.clk, 2)
    out_val = []
    w_count = 0; r_count = 0
    w_stop =0; r_stop=0
    for i in range(w_burst*4*n_burst+stop_write*n_burst):
        if(w_stop==(stop_write-1)):
            w_stop =0
            w_count=0
        if(r_stop==(stop_read-1)):
            r_stop=0
            r_count =0
        if(r_count==(r_burst)):
            r_stop = r_stop+1
            dut.dout_ready <=0
        if(w_count==(w_burst)):
            w_stop = w_stop+1
            dut.din_valid <=0
        else:
            dat = struct.pack('>4Q',*(din[::-1,w_count].astype(int)))
            dut.din_valid <=1
            dut.dout_ready <=1
            din_val.set_buff(dat)
            dut.din <= din_val
            w_count = w_count+1
            r_count = r_count+1
        await ClockCycles(dut.clk, 1) 
        val = dut.dout_valid.value
        if(val):
            out = dut.dout.value
            out_val.append(out)        
    gold_val = (din.T).flatten()
    for i in range(len(out_val)):
        #print("out: %x   gold:%x" %(out_val[i], gold_val[i%(4*w_burst)]))
        assert (int(gold_val[i%(4*w_burst)])==int(out_val[i])), "fail in avg {}".format(i)

