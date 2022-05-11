import cocotb, random, string
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


@cocotb.test()
async def pattern_search_test(dut, iters=192, header='hello world', msg="red car"):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    #
    dut.rst.value =0
    dut.din.value =0
    dut.din_valid.value =0
    await ClockCycles(dut.clk,1)
    
    ##generate random letters
    random.seed(10)
    letters = string.ascii_lowercase
    din = ''.join(random.choice(letters) for i in range(iters))
    insert = random.randint(0,iters-1) 
    din = din[:insert]+header+msg+din[insert:]
    din = list(din.encode('ascii'))

    gold = list(msg.encode('ascii'))

    cocotb.fork(write_data(dut, din))
    out = await read_data(dut, gold)
    msg_out = ''.join(chr(i) for i in out)
    print("input msg:  "+msg)
    print("output msg: "+msg_out)
    await ClockCycles(dut.clk, 1000)
    


async def write_data(dut, data):
    for dat in data:
        dut.din.value = int(dat)
        dut.din_valid.value = 1
        await ClockCycles(dut.clk, 1)
        dut.din_valid.value = 0
        await ClockCycles(dut.clk, random.randint(0, 60))

async def read_data(dut,gold):
    count =0
    out = []
    while(count < len(gold)):
        valid = int(dut.info_valid.value)
        if(valid):
            dout = int(dut.info_data.value)
            print("gold:"+chr(gold[count])+" rtl:"+chr(dout))
            assert (dout == gold[count])
            out.append(dout)
            count +=1
        await ClockCycles(dut.clk,1 )
    return out
        





