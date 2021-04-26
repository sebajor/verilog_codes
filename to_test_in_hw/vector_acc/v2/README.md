The new accumulation signal must be in the first word of the packet.
For example if you have an accumlator with 64 elements and you want
to accumulate 5 times you need to assert the signal in the index 0
of the 5 vector (ie if 0 is the starting point the new acc signal, which
denotes the end of an accumualtion and the begining of other one, should
be asserted in the the cycle 5*64)
