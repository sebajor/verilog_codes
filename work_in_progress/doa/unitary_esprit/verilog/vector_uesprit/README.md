# Vector Uesprit

In this folder we use an FFT to separate the bands and perform the unitary esprit in each channel.

We have two flavors of this unitary esprit:
- Pointwise: Here we take each channel as an independant band and calculate the uesprit in each one.

- Band: We accumulate adjacent FFT channels to generate bands where the uesprit is calculated.

