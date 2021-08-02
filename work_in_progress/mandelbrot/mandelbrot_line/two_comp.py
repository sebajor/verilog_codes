import numpy as np

def two_comp_pack(values, n_bits, bin_pt):
    """ Values are a numpy array witht the actual values
        that you want to set in the dut port
        n_bits: number of bits
        n_int: integer part of the representation
    """
    n_int = n_bits-bin_pt
    quant_data = (2**bin_pt*values).astype(int)
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


       



