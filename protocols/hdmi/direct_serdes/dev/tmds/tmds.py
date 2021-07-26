import numpy as np


def tmds(din, cnt_prev):
    din = np.array(din, dtype=np.uint8)
    din_b = np.unpackbits(din)
    N1 = np.sum(din_b)
    N0 = 8-N1
    q_m = np.zeros(9)
    q_m[0] = din_b[0]
    if(N1>4 or (N1==4 && ~din_b[0])):
        for i in range(7):
            q_m[i+1] = ~((q_m[i] ^ din_b[i]).astype(bool)).astype(np.uint8)
        q_m[9] = 0
    else:
        for i in range(7):
            q_m[i+1] = (q_m[i] ^ din_b[i])
        q_m[9] = 1
   q_out = np.zeros(10)
   N1_q = np.sum(q_m[0:7])
   N0_q = 8-N1_q
   if((cnt_prev==0) or (N1_q==N0_q)):
       q_out[9] = ~q_m[8]
       q_out[8] = q_m[8]
       if(q_m[8]):
            q_out[:7] = q_m[:7]
            cnt = cnt_prev + N0_q-N1_q
        else:
            cnt = cnt_prev + N1_q-N0_q
            q_out[:7] = np.invert(q_m[:7].astype(bool)).astype(np.uint8)
    else:
        if((cnt_prev>0 and N1_q>N0) or (cnt_prev<0 and N0_q>N1_q)):
            q_out[9] =1
            q_out[8] = q_m[8]
            q_out[:7] = np.invert(q_m[:7].astype(bool)).astype(np.uint8)
            cnt = cnt_prev + 2*q_m[8] +N0_q -N1_q
        else:
            q_out[9] = 0
            q_out[8] = q_m[8]
            q_out[:7] = q_m[:7]
            cnt = cnt_prev- 2*((~q_m[8].astype(bool)).astype(int)+N1_q-N0_q)
    return [q_out, cnt]




