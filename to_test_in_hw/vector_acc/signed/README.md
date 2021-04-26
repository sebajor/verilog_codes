Vector Accumulator:
Is like a vector addition ie:

[ ch0 ch1 ch2 ... ]
[ ch0' ch1' ch2' ... ] -> 

vect acc =[ch0+ch0', ch1+ch1'+....]

It usefull when you have time multiplexed signals (like a FFT which gives
you each channel after N cycles, so with this module you could add succesives
FFTs)


*Synth max freq prediction (din=36,vector_len=64,dout=64): 273mhz

