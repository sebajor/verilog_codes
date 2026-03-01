
This trick works when you have two real only input data x,y then you can put them in in the format z=x+iy and compute the FFT over z.
Then you can recover the FFT(x) and FFT(y) from the FFT(z).

X[k] = 1/2(Z[k]+conj(Z[N-k]))
Y[k] = -i/2(Z[k]-conj(Z[N-k]))

the only two cases where the pairing its with them selves is k=0 and k=N/2.

The biggest problem here is that the DIF FFT gives the data in bitreversal, so here I have to find the smart way to store and access the data.
