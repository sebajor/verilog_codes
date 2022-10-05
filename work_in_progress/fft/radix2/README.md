
The typical technique used in the FFT is to exploit the symetries of the DFT computation.

$$ \hat{X}_{k} = \sum_{n=0}^{N-1} x[n] \cdot e^{-j2\pi nk/N}$$

$$
    = \sum_{n=0}^{N/2-1} x[2n] \cdot e^{-j2\pi (2n)k/N} + 
    e^{-j2\pi k/N} \left(\sum_{n=0}^{N/2-1} x[2n+1] \cdot e^{-j2\pi (2n)k/N} \right)
$$

$$
    \hat{X}_{k} =  \sum_{n=0}^{N/2-1} x[2n]\cdot W_{N}^{2nk} + 
    W_{N}^{k} (\sum_{n=0}^{N/2-1} x[2n+1] W_{N}^{2nk}
$$

Then we separate the N point DFT in two of size N/2, the FFT algorithm keeps reducing the FFT size allowing a reduction in the multiplications.

The previous method was the decimation in time mode of the FFT. When implementing this in hardware it will ask you to divide the data in a weird fashion (bit reversal indexing) there is also a decimation in frequency version that its computed in a normal input indexing but it deliver the FFT output in bit reversal order.

The decimation in frequency uses other equivalent symmetry, it decompose the inputs in lower/upper half of the samples to compute the DFT.

$$
    \hat{X}_{k} = \sum_{n=0}^{N/2-1} x[n] W_{N}^{nk} + \sum_{n=N/2}^{N-1} x[n]W_{N}^{nk}
$$
$$
    = \sum_{n=0}^{N/2-1}x_{low}W_{N}^{nk}+ \sum_{n=0}^{N/2-1}x_{high}W_{N}^{(n+N/2)*k} = \sum_{n=0}^{N/2-1}(x_{low}-e^{j\pi k}x_{high})W_{N}^{nk}
$$




# DFT structure

As the radix 2 implies we could reduce the DFT computations, but its not necesary to use just multiples of 2. 
The core idea is to divide N as a product of smaller numbers. 

Lets say that we can express $N=M+L$ then we could indexing the DFT using $n=Ml+m$ where $m \in [0,..,M-1]$ and $l \in [0,..,L-1]$.

$$
    \hat{X}_{k} = \hat{X}_{r,s} = \sum_{m=0}^{M-1}\sum_{l=0}^{L-1} x[l,m] W^{(Ml+m)(Lr+s)} \\
    = \sum_{m=0}^{M-1} W^{Lmr}W^{ms}\sum_{l=0}^{L-1}x[l,m]W^{Msl}
$$

This is equivalente to think in arranging the values in a matrix of size $MxL$, then calculate the DFT of each column, then multiply the result for the correspondant twiddle factor $W^{ms}$ and finally compute the DFT on the rows.


For the radix implementations then we have that $N=r^{m}$ so in the first iteration we decompose $N= r x N/r$ and keep decomposing $N/r=r x N/r^2$, etc.


 

