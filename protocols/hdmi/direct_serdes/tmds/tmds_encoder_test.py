import numpy as np
import tmds
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def tmds_encode_test(dut, iters=255):
    """
    just check the video 
    """
    clock = Clock(dut.pxl_clk, 10, units='ns')
    cocotb.fork(clock.start())
    dut.mode <= 0   #to reinitialize the internal counter acc
    dut.video_data <=0
    dut.data_island <=0
    dut.control_data <=0
    await ClockCycles(dut.pxl_clk,1)
    dut.mode <= 1   #video 
    np.random.seed(10)
    din = np.random.randint(255, size=iters)
    #din = np.ones(iters)*50
    count =0 
    ##the module has 1 cycle of delay..
    dut.video_data <= int(din[0])
    await ClockCycles(dut.pxl_clk,1)
    for i in range(iters-1):
        dut.video_data <= int(din[i+1])
        await ClockCycles(dut.pxl_clk, 1)
        gold, count = tmds.tmds_encode(din[i], count)
        dout = dut.tmds.value
        #print("gold:"+np.array2string(gold.astype(int))[1:-1][::2]+ "\t dout:"+str(dout))
        assert (np.array2string(gold.astype(int))[1:-1][::2]==str(dout))

