import numpy as np
import ipdb

def butterfly_dit(x,y, w):
    """
    """
    x_out = x+y*w
    y_out = x-y*w
    return [x_out, y_out]

def butterfly_dif(x,y,w):
    """
    """
    x_out = x+y
    y_out = (x-y)*w
    return [x_out, y_out]




def DFT_dif(data):
    """
    Notes:
    In each iteration the number of butterflies block get duplicated
    first start with one big block that joins i and i+N/2, the second iteration
    is composed by 2 blocks, one goes from 0 to N/2 and joins i with i+N/4, 
    the second block goes from N/2 to N and also joins i with i+N/4.
    """
    data = data.astype(complex)
    iters = int(np.log2(len(data)))
    #fist divide the data in upper/lower half
    #x_low = data[:len(data)//2]
    #x_high = data[len(data)//2:]
    dat = np.zeros([iters+1, len(data)], dtype=complex)
    dat[0,:] = data
    for i in range(iters):
        dft_idx = np.arange(2**(iters-1-i))*2**i    #check!
        w_ = np.exp(-1j*2*np.pi*dft_idx/2**(iters))
        for j in range(2**i):#(i+1):
            sub_data = dat[i,len(data)//2**i*j:len(data)//2**i*(j+1)]
            #print("i: %i j:%i"%(i,j))
            #print(sub_data)
            #print("\n")
            x_low = sub_data[:len(sub_data)//2]
            x_high = sub_data[len(sub_data)//2:]
            x,y =butterfly_dif(x_low, x_high, w_)
            dat[i+1,len(data)//2**i*j:len(data)//2**i*(j+1)] = np.concatenate([x,y])
    return dat
     



def bit_reversal_mapping(bitsize):
    index = np.arange(2**bitsize)
    bin_data = [int(np.binary_repr(x, width=bitsize)[::-1],2) for x in index]
    return bin_data
    



"""
        print(i)
        dft_idx = np.arange(2**(iters-1-i))*2**i    #check!
        dft_idx = np.tile(dft_idx, 2**i)            #check!
        w_ = np.exp(-1j*2*np.pi*dft_idx/2**(iters))
        ipdb.set_trace()
        x, y = butterfly_dif(x_low, x_high,w_)
        #the good stuff is that it seems that the x ends being  add with the x
        #and the y with the y, so we could join them 
        x_low = np.concatenate([x[:len(data)//4], y[:len(data)//4]])
        x_high = np.concatenate([x[len(data)//4:], y[len(data)//4:]]) 
    x,y = butterfly_dif(x_low, x_high, np.ones(2**(iters-1)))
    return x,y
"""


if __name__=='__main__':
    threshold = 1e-10
    #input_data = np.arange(64)
    input_data = np.random.random(128)
    data = DFT_dif(input_data)
    out = data[-1,:]
    #reorder
    bitmap = bit_reversal_mapping(int(np.log2(len(out))))
    fft_data = out[bitmap]
    error = np.abs(fft_data-np.fft.fft(input_data))
    assert((error<threshold).all())

        

    

