import numpy as np
import optparse
import sys, os
sys.path.append('../')
from two_comp import two_comp_pack

def quantize_weight(folder_in, folder_out, width, point):
    files = os.listdir(folder_in)
    for names in files:
        if(names.endswith('.txt')):
            aux = names.split('.txt')[0]
            din = np.loadtxt(folder_in+names)
            quant = two_comp_pack(din, width, point)
            f = open(folder_out+aux+'.mem', 'w')
            for i in range(len(quant)):
                data_b = bin(int(quant[i]))[2:]
                f.write(data_b)
                f.write('\n')
            f.close()



parser = optparse.OptionParser()

parser.add_option('-i', '--width',
                    dest='width',
                    type='int',
                    help='bitwidth')
parser.add_option('-t', '--pt',
                    dest='pt',
                    type='int',
                    help='din bit point location')
parser.add_option('-f', '--folder_out',
                    dest='folder_out',
                    type='string',
                    help='folder where the binary value is saved')
parser.add_option('-w', '--folder_in',
                    dest='folder_in',
                    type='string',
                    help='folder where the data is stored')

(opt, args) = parser.parse_args()
quantize_weight(opt.folder_in, opt.folder_out, opt.width, opt.pt)
