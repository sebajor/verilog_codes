## Wideband FFT


To have a wideband FFT you ave to be able to process several streams of data in
a simoultaneous way. 

The idea is to follow the Cooley-Tukey trick and build a big FFT from smaller ones
then you perform a pipeline FFT over each data stream and then combined them using 
a parallel FFT to produce the final one.

To do that the main trick is to find a way to reorder the FFTs of the streams for
the parallel FFT. A way to simplify the parallel FFT is when you have 4 or 8 streams
then you can use radix-8 and radix-4 schemes.



