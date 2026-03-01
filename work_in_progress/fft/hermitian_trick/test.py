import numpy as np





def bit_reverse_indices(n):
    """Return array of bit-reversed indices for 0..n-1."""
    bits = int(np.log2(n))
    indices = np.arange(n)
    reversed_indices = np.array([
        int(f"{i:0{bits}b}"[::-1], 2) for i in indices
    ])
    return reversed_indices


def get_pairing(n):
    """
    Return the pairings in natural order..
    """
    pairs = np.array([-x%n for x in range(n)])
    return pairs



if __name__ == '__main__':
    N = 32
    fft_out_ind = bit_reverse_indices(N)
    pairs = get_pairing(N)
    ##the next line tell us where we are
    pair_fft_out = pairs[fft_out_ind]
    ##So we will iterate over the fft_output indices and see if the correspondant 
    ##pair had appear or not.. if it already appear then you can do the sum right away
    ready = np.zeros(N, dtype=bool)
    for i in range(1,N+1):
        search = pair_fft_out[i-1]
        if(search in fft_out_ind[:i]):
            ready[i-1] = True
        else:
            ready[i-1] = False

