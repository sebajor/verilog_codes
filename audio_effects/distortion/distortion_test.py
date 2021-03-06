import cocotb, struct
import numpy as np
from cocotb.clock import Clock 
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
import wave


@cocotb.test()
async def distortion_test(dut):
    clk = Clock(dut.clk, 10, units="ns")
    cocotb.fork(clk.start())

    audio_in = wave.open('440Hz.wav')
    audio_out = wave.open('out.wav', 'wb')
    audio_out.setnchannels(1)
    audio_out.setsampwidth(audio_in.getsampwidth())
    audio_out.setframerate(audio_in.getframerate())

    nframes = int(audio_in.getnframes())
    dut.dout_tready <= 1
    await ClockCycles(dut.clk, 1)
    for i in range(nframes):
        frame = audio_in.readframes(1)
        #dat0, dat1 = struct.unpack('2h', frame)
        dat0, = struct.unpack('h', frame)
        dut.din <= dat0
        dut.din_tvalid <= 1
        await ClockCycles(dut.clk, 1)
        val = dut.dout_tvalid.value
        if(int(val)):
            raw_out = struct.pack('h', dut.dout.value.signed_integer)
            audio_out.writeframes(raw_out)




