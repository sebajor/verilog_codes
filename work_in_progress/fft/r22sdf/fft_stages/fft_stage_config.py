import numpy as np
import sys
sys.path.append('../../../../cocotb_python/')
from two_comp import two_comp_pack
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("-n", "--stage", type=int, dest="stage")
parser.add_argument("-bit_width", '--bit_width', type=int, dest="bit_width")
parser.add_argument("-bit_point", '--bit_point', type=int, dest="bit_point")
parser.add_argument("-f", '--folder', type=str, default="twiddles", dest="folder")



def get_stage_twiddle_factors(stage_number):
    N = stage_number*2
    subset_index = stage_number//2
    twiddles = np.ones(N, dtype=complex)
    W_n = np.exp(-1j*2*np.pi/N)
    twiddles[subset_index:subset_index*2] = W_n**(np.arange(subset_index)*2)
    twiddles[subset_index*2:subset_index*3] = W_n**(np.arange(subset_index))
    twiddles[subset_index*3:] = W_n**(np.arange(subset_index)*3)
    return twiddles


def fix_twiddle_factors(stage_number, bit_width, bit_point):
    twiddles = get_stage_twiddle_factors(stage_number)
    re_data = two_comp_pack(twiddles.real, bit_width, bit_point)
    im_data = two_comp_pack(twiddles.imag, bit_width, bit_point)
    re_bin = [bin(int(x))[2:] for x in re_data]
    im_bin = [bin(int(x))[2:] for x in re_data]
    return re_bin, im_bin

def write_bin_non_trivial_twiddle(stage_number, bit_width, bit_point, folder='twiddles'):
    """
    We dont save the 1
    """
    os.makedirs(folder, exist_ok=True)
    twidd_filename = os.path.join(folder, "stage"+str(stage_number)+"_"+str(bit_width)+"_"+str(bit_point))
    f = open(twidd_filename, 'w')
    re_bin, im_bin = fix_twiddle_factors(stage_number, bit_width, bit_point)
    re_bin = np.array(re_bin)
    im_bin = np.array(im_bin)
    re_bin = (re_bin.reshape((stage_number//2, -1))[1:,1:]).flatten()
    im_bin = (im_bin.reshape((stage_number//2, -1))[1:,1:]).flatten()
    for re, im in zip(re_bin, im_bin):
        f.write(re)
        f.write(im)
        f.write('\n')
    f.close()




if __name__ == '__main__':
    args = parser.parse_args()
    write_bin_non_trivial_twiddle(args.stage, args.bit_width, args.bit_point, 
                                  args.folder)

