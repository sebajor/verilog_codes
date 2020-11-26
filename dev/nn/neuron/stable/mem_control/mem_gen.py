import numpy as np
import struct

def mem_gen(addr_len, dtype):
    f = open("weight_test.mem", 'w')
    dat = np.linspace(0,2**addr_len-1,2**addr_len)
    for i in range(len(dat)):
        data_hex = struct.pack(dtype, dat[i])
        f.write(data_hex.encode('hex'))
        f.write('\n')
    f.close()

if __name__ == '__main__':
    mem_gen(16, '>H')


