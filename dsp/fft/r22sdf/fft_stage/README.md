The r22sdf has the advantage that it can be build by stages, where each stage is composed by a BF_1, BF_2 and a complex multiplication of twiddle factors.


In each module the buffer size is cut at half.. So for example a 64 point fft would be composed by:
----------------------------------------    ----------------------------------------     ----------------------------------------
|BF1(32) -> BF2(16) --> twiddle factors| -->|BF1(8) -> BF2(4) --> twiddle factors  | --> |BF1(2) -> BF2(1) --> twiddle factors  |
|--------------------------------------|    |--------------------------------------|     |--------------------------------------|


To generate the twiddle factors we take the last buffer size parameter of the BF2. There are 4 subsets of twiddle factors that we need to create,
the first one are just 1, the second W_n**(2*i), the third W_n**(i) and the fourth one W_n**(3**i) with i ranging from (0, bf2_buffer_size/4-1)
and n=bf1_buffer_size*2.

The special one is the last stage where all the twiddle factors will be 1.

Just for easing we just will name each stage by the BF1 buffer size





