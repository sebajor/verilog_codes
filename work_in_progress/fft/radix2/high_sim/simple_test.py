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
    iters = int(np.log2(len(data)))
    #fist divide the data in upper/lower half
    x_low = data[:len(data)//2]
    x_high = data[len(data)//2:]
    for i in range(iters):
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


if __name__=='__main__':
    x,y = DFT_dif(np.arange(16))
        

    

