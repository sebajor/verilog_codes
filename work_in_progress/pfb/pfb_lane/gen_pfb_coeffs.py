import numpy as np
import scipy as sp
import sys, os, argparse
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack


def compute_pfb_coeffs(M,P,lanes,window_fn="hamming"):
    """
    M           :Filter size 
    P           :taps
    lanes       :number of parallel lanes
    lane_number :number of the actual lane
    window_fn   :window function
    """
    win_coeff = sp.signal.get_window(window_fn, M*P)
    sinc = np.sinc(np.arange(M*P)/M-P/2)
    coeffs = win_coeff*sinc
    #now we reorder this coefficients, it supose that is divisible
    ##the index are lane, tap, values
    sub_coeffs = np.swapaxes(coeffs.reshape((lanes, -1, P)),1,2)
    return sub_coeffs
    

def quantize_data(folder_path, data, data_width, data_point, debug=True):
    """
    Quantize the coefficients and save each in a file inside the folder_path
    The name of each file is pfb_coeff_{lane}_{tap}
    """
    os.makedirs(folder_path, exist_ok=True)
    if(debug):
        np.save(os.path.join(folder_path,'coeffs.npy'), data)
    for i in range(data.shape[0]):
        for j in range(data.shape[1]):
            name = os.path.join(folder_path,"pfb_coeff_"+str(i)+"_"+str(j))
            quant = two_comp_pack(data[i,j,:], data_width, data_point)
            f = open(name, 'w')
            for val in quant:
                data_b = bin(int(val))[2:]
                f.write(data_b)
                f.write('\n')
            f.close()

def generate_pfb_coeffs(M,P,lanes,folder_path, coeff_width, 
        coeff_point,window_fn="hamming", debug=True):
    coeffs =  compute_pfb_coeffs(M,P,lanes,window_fn=window_fn)
    quantize_data(folder_path, coeffs, coeff_width, coeff_point, debug=debug)


##
parser = argparse.ArgumentParser()

parser.add_argument("-f", "--folder", dest="folder_path", default="pfb_coeffs")
parser.add_argument("-M", "--pfb_size", dest="pfb_size", type=int)
parser.add_argument("-P", "--taps", dest="taps", type=int)
parser.add_argument("-L", "--lanes", dest="lanes", type=int)
parser.add_argument("-bw", "--bitwidth", dest="bitwidth", type=int)
parser.add_argument("-bp", "--bitpoint", dest="bitpoint", type=int)
parser.add_argument("-w", "--window", dest="window", default="hamming")
parser.add_argument("-d", "--debug", dest="debug", action="store_true")


if __name__ == '__main__':
    args = parser.parse_args()
    generate_pfb_coeffs(args.pfb_size, args.taps, args.lanes, args.folder_path,
            args.bitwidth, args.bitpoint, args.window, debug=args.debug)

    
    













