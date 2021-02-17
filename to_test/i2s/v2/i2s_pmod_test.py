import cocotb, struct
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

def create_adc_data(data):
    out =[]
    for i in range(len(data)):
        aux1 = (data[i]>>8*3)&255
        aux2 = (data[i]>>8*2)&255
        aux3 = (data[i]>>8*1)&255
        aux4 = (data[i])&255
        aux = np.array([aux1,aux2,aux3,aux4], dtype=np.uint8)
        dat = np.unpackbits(aux)
        out.append(dat.flatten())
    out = np.array(out)
    out = out.flatten()
    out = np.hstack([np.zeros(32), out])
    return out



@cocotb.test()
async def i2s_pmod_test(dut, duration=2048):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clock.start())
    np.set_printoptions(formatter={'int':hex})
    ##dac test
    """
    dac_data = [0xaabbccdd, 0x11223344]
    #dac_data =  [0xfffffff2, 0xfffffff3]#0x1122334455667788]
    data_l, data_r = await dac_test(dut, dac_data)
    print("dac test outputs")
    print(data_l.astype(int))
    print(data_r.astype(int))
    #the fist 2 values are zero because we are using a buffer to
    #output the data, to avoid overwrite the output data whit the 
    #new one
    """
    #adc test
    adc_data = [0x1, 0x2, 0xaabbccdd, 0x11223344, 0xffffffff, 0xaabbccdd, 0xffffffff, 0xaabbccdd]
    adc_dat = create_adc_data(adc_data)
    dut.adc_dat <= 0;
    dat_r, dat_l = await adc_test(dut, adc_dat) 
    print(dat_r)
    print(dat_l)

async def dac_test(dut, dac_data, duration=2048):
    """Currently it only support 2 words in the dac data,
     like is just a simple check i keep it that way (because i am lazy)
    """
    dut.dac_r_tdata <= dac_data[0]
    dut.dac_l_tdata <= dac_data[1]
    dut.dac_tvalid <= 3;
    dac_r = []
    dac_l = []
    await ClockCycles(dut.clk, 1)
    for i in range(duration):
        #if(i%1024==0):
            #dut.dac_tdata <= dac_data[1]
        dac_sclk_dly = dut.dac_sclk.value
        dac_lrck = dut.dac_lrck.value
        ##the data its delayed one sclk respect to lrck
        await ClockCycles(dut.clk, 1)
        dac_sclk = dut.dac_sclk.value
        if(~int(dac_sclk) & int(dac_sclk_dly)):
            ##detect falling edge of the sclk
            if(dac_lrck):
                dac_l.append(dut.dac_sdat.value)
            else:
                dac_r.append(dut.dac_sdat.value)
    dac_l = np.array(dac_l)
    dac_r = np.array(dac_r)
    dac_l = dac_l.reshape([-1,8])
    dac_r = dac_r.reshape([-1,8])
    ##the bit order should be bigger.. but we wrote tdata as little (seems)
    left_data = np.packbits(dac_l.astype(np.uint8)[::-1], axis=1, bitorder='big')
    right_data = np.packbits(dac_r.astype(np.uint8)[::-1], axis=1, bitorder='big')
    #left_data = np.packbits(dac_l.astype(np.uint8), axis=1, bitorder='little')
    #right_data = np.packbits(dac_r.astype(np.uint8), axis=1, bitorder='little')
    left_data = left_data.reshape([-1,4])
    right_data= right_data.reshape([-1,4])
    dout_l = np.zeros(left_data.shape[0])
    dout_r = np.zeros(left_data.shape[0])
    for i in range(left_data.shape[0]):
        dout_l[i] = (left_data[i,3]<<24)+(left_data[i,2]<<16)+(left_data[i,1]<<8)+(left_data[i,0])
        dout_r[i] = (right_data[i,3]<<24)+(right_data[i,2]<<16)+(right_data[i,1]<<8)+(right_data[i,0])
    return dout_l, dout_r 


async def adc_test(dut, data):
    adc_l = []
    adc_r = []
    count = 0
    prev = 0
    await ClockCycles(dut.clk, 1)
    while(count < len(data)):
        sclk = dut.adc_sclk.value
        lrck = dut.adc_lrck.value
        adc_val = dut.adc_tvalid.value
        if(~int(sclk)&int(prev)):
            dut.adc_dat <= int(data[count])
            count = count+1
        if(adc_val&1):
            adc_value = dut.adc_r_tdata.value
            adc_r.append(int(adc_value))
            dut.adc_tready <= 3
        if(adc_val&2):
            adc_value = dut.adc_l_tdata.value
            adc_l.append(int(adc_value))
            dut.adc_tready <= 3
        prev = sclk
        await ClockCycles(dut.clk, 1)
        dut.adc_tready <= 0;
    adc_l = np.array(adc_l)
    adc_r = np.array(adc_r)
    return adc_r, adc_l

#async def adc_test(dut, data):
    """ data: numpy array of values to transmit, (binary data ie np.unpackbits)
        the even data is left and the right is the odd
        the data is transmited in the rising edge of the sclk
    """

"""
    duration = len(data)
    index = 0
    recv_data_r = []
    recv_data_l = []
    await ClockCycles(dut.clk,1)
    while(1):
        if(i==len(data)-1):
            break
        prev_sclk = dut.adc_sclk.value
        await ClockCycles(dut.clk,1)
        dut.adc_tready <= 0;
        actual_sclk = dut.adc_sclk.value
        if(~(prev_sclk)&&actual_sclk):
            dut.adc_dat <= data[index]
            index = index+1
        valid = dut.adc_tvalid.value
        if(int(valid)&1):
            dat = dut.adc_tdata.value
            recv_data_l.append(dat)
            dut.adc_tready <= 1
        if(int(valid)&2):
            dat = dut.adc_tdata.value
            recv_data_r.append(dat)
            dut.adc_tready <= 2
    recv_data_r = np.array(recv_data_r)
    recv_data_l = np.array(recv_data_l)
    
    print(recv_data_r)

    return [recv_data_r, recv_data_l] 

"""
