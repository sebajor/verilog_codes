import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
import sys
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def moving_
