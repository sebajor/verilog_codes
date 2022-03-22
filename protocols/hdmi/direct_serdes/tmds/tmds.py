import numpy as np
from operator import xor

###
### Author: Sebastian Jorquera
###


def tmds_encode(din, cnt_prev):
    #ipdb.set_trace()
    din = np.array(din, dtype=np.uint8)
    din_b = np.unpackbits(din).astype(bool)[::-1]
    N1 = np.sum(din_b)
    N0 = 8-N1
    q_m = np.zeros(9, dtype=bool)
    q_m[0] = din_b[0]
    if(N1>4 or (N1==4 and ~din_b[0])):
        for i in range(7):
            q_m[i+1] = ~(xor(q_m[i],din_b[i+1]))
        q_m[8] = 0
    else:
        for i in range(7):
            q_m[i+1] = xor(q_m[i], din_b[i+1])
        q_m[8] = 1
    q_out = np.zeros(10, dtype=bool)
    N1_q = np.sum(q_m[0:8])
    N0_q = 8-N1_q
    if((cnt_prev==0) or (N1_q==N0_q)):
        q_out[9] = ~q_m[8]
        q_out[8] = q_m[8]
        if(q_m[8]):
            q_out[:8] = q_m[:8]
            cnt = cnt_prev + N1_q-N0_q
        else:
            q_out[:8] = ~q_m[:8]
            cnt = cnt_prev + N0_q-N1_q
    else:
        if((cnt_prev>0 and N1_q>N0_q) or (cnt_prev<0 and N0_q>N1_q)):
            q_out[9] =1
            q_out[8] = q_m[8]
            q_out[:8] = ~q_m[:8]
            cnt = cnt_prev + 2*q_m[8] +N0_q -N1_q
        else:
            q_out[9] = 0
            q_out[8] = q_m[8]
            q_out[:8] = q_m[:8]
            cnt = cnt_prev- 2*(~q_m[8])+N1_q-N0_q
    return [q_out[::-1], cnt]



def tmds_decode(din):
    """din = np.array of len 10 with boolean values
    """
    din_cp = np.copy(din)
    dout = np.zeros(8, dtype=bool)
    if(din[9]):
        din_cp[:8] = ~din_cp[:8]
    dout[0] = din_cp[0]
    if(din_cp[8]):
        for i in range(7):
            dout[i+1] = xor(din_cp[i+1], din_cp[i])
    else:
        for i in range(7):
            dout[i+1] = ~(xor(din_cp[i+1], din_cp[i]))
    dout_int = np.packbits(dout[::-1].astype(np.uint8))
    return dout, dout_int

        




