# Radix $2^2$ Single-path Delay Feedback DIF FFT ($R2^2 SDF$ FFT)

# Notes about the control signals
The first N/2 cycles the 2-to-1 mux in the first butterfly are in position 0 and the butterfly is idle. On the next N/2 cycles the mux changes to 1 and the butterfly compute the 2-point DFT:
$$Z_{1}(n) = x(n)+x(n+N/2) $$
$$Z_{1}(n+N/2) = x(n)-x(n+N/2) $$ 

$Z_1(n)$ is sent to the next stage while $Z_{1}(n+N/2)$ is sent to feedback register.

In the second butterfly we have 2 control signals. When the second control signal is zero the butterfly acts the same as the butterfly 1, when is 1 then a multiplication by -j occurs but that can be expressed just switching the imaginary part with the real part and generating a substraction instead of a addition.

When computing a N size DFT the first N/2 iterations the control signal 1 is zero, the last N/2 the control 1 signal is 1. The -j multiplication only occurs when the last N/4 portion of the data is output by the butterfly 1.
I used the diagram in the paper **FPGA Implementation of Pipeline Digit-Slicing Multiplier-Less Radix 22 DIF SDF Butterfly for Fast Fourier Transform Structure** so the control 2 has a NOT.



## Good pages:
- [Implementation](https://github.com/briansune/FFT-R22SDF)
- [Implementation](https://github.com/nanamake/r22sdf)
- Design of Efficient Pipelined Radix-22Single Path Delay Feedback FFT
- ASIC FFT Processor for MB-OFDM UWB System (Thesis)

