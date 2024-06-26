import numpy as np

def two_comp_pack(values, n_bits, bin_pt, mode='truncate'):
    """ Values are a numpy array witht the actual values
        that you want to set in the dut port
        n_bits: number of bits
        n_int: integer part of the representation
    """
    n_int = n_bits-bin_pt
    if(mode=="truncate"):
        quant_data = (2**bin_pt*values).astype(int)
    elif(mode=="near"):
        quant_data = np.rint((2**bin_pt*values))
    ovf = (quant_data>2**(n_bits-1)-1)&(quant_data<2**(n_bits-1))
    if(ovf.any()):
        raise "Cannot represent one value with that representation"
    mask = np.where(quant_data<0)
    quant_data[mask] = 2**(n_bits)+quant_data[mask]
    return quant_data

def two_comp_unpack(values, n_bits, bin_pt):
    """Values are integer values (to test if its enough to take
    get_value_signed to obtain the actual value...
    """
    n_int = n_bits-bin_pt
    mask = values>2**(n_bits-1)-1 ##negative values
    out = values.copy()
    out[mask] = values[mask]-2**n_bits
    out = 1.*out/(2**bin_pt)
    return out


def two_pack_multiple(values, n_bits, bin_pt):
    out =0
    bin_val = two_comp_pack(values, n_bits, bin_pt)
    for i in range(len(values)):
        #bin_val = two_comp_pack(np.array(values[i]), n_bits, bin_pt)
        out = out | bin_val[i]<<(n_bits*i)
    return out


#def two_unpack_multiple(values, n_bits, bin_pt):
def pack_multiple(data, mult_factor, nbits):
    """Concatenate data in a single number
        data: data to concatenate
        mult_factor: factor to interleave
        nbits:  the number of bits to represent the signal
    """
    out = 0
    for i in range(mult_factor):
        out += int(data[i])<<(i*nbits)
    return out



def unpack_multiple(data, mult_factor, nbits):
    """To separate interleaved data
        data: interleaved data
        mult_factor: interleave factor
        nbits:
    """
    out = np.zeros(mult_factor)
    for i in range(mult_factor):
        aux = int(data>>(nbits*i))
        mask = 2**nbits-1
        dat = aux & mask
        out[i] = dat
    return out


       



