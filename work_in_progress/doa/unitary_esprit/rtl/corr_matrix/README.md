The vector accumulator is behaving weird, it works for continuous accumulation
(ie din_valid=1 always)but for some cases when the new_acc and valid are in a 
weird configuration the output is delayed in one sample.. 

Like the output of the FFT in the roach is continous I could live with that..
but its a bug!!!
