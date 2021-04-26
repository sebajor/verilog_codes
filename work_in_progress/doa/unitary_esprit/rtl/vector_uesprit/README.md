this module first make the transformation y = Q^{H}x, then calculates the 
correlation matrix R_{yy} = Q^{H}xx^{T}Q (per FFT channel).

Here we have only 2 antennas to make the search, so the correlation matrix
is really a N_channelsx2x2.

The typical uesprit just sum in the N_channels dimmension so you have
just a 2x2--> If you want to make that you need to reeplace the vector accs
for just an accumulator (or a moving average)

The advantage to have N_acc matrices is that you could detect one doa per 
matrix.. So in theory, we could detect N_acc sources if they are transmitting 
in different frequencies.


The module no_linear moduledoesnt make the linear algebra (eigenvalue 
and eigenvector decomposition), to check if the system is working properly 
we make the linear algebra in the testbench.


