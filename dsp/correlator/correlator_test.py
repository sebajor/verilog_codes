import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge
from cocotb.clock import Clock
import sys
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

@cocotb.test()
async def correlator_test(dut, vec_len=64, iters=10, din_width=16, din_pt=14,
        dout_width=32, dout_pt=16, thresh=0.01, cont=1, burst_len=10):

    cont_frames = 1
    back = 0

    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(9)
    
    #setup dut
    dut.new_acc.value =0
    dut.din_valid.value =0
    dut.din1_re.value =0
    dut.din1_im.value =0
    dut.din2_re.value =0
    dut.din2_im.value =0
    await ClockCycles(dut.clk, 5)
    
    #input data
    acc_len = 10#np.random.randint(1024)
    print('Acc len: %i'%(acc_len))

    re1 = np.random.random(size=[acc_len, vec_len, iters])-0.5
    im1 = np.random.random(size=[acc_len, vec_len, iters])-0.5
    re2 = np.random.random(size=[acc_len, vec_len, iters])-0.5
    im2 = np.random.random(size=[acc_len, vec_len, iters])-0.5
    din1 = re1+1j*im1;  din2 = re2+1j*im2
    
    r11 = np.sum(din1*np.conj(din1), axis=0)
    r22 = np.sum(din2*np.conj(din2), axis=0)
    r12 = np.sum(din1*np.conj(din2), axis=0)
    gold = [r11.T.flatten(),r22.T.flatten(),r12.T.flatten()]
    
    din1_re = two_comp_pack(re1.flatten(), din_width, din_pt).reshape(re1.shape)
    din1_im = two_comp_pack(im1.flatten(), din_width, din_pt).reshape(re1.shape)
    din2_re = two_comp_pack(re2.flatten(), din_width, din_pt).reshape(re1.shape)
    din2_im = two_comp_pack(im2.flatten(), din_width, din_pt).reshape(re1.shape)

    data = [din1_re, din1_im, din2_re, din2_im]
    cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    await write_data(dut, data, back=back, cont_frames=cont_frames)


async def write_data(dut, data, back=0, cont_frames=1):
    dut.new_acc.value = 1
    await ClockCycles(dut.clk, 1)
    dut.new_acc.value = 0
    iters = data[0].shape[2]
    acc_len = data[0].shape[0]
    vec_len = data[0].shape[1]
    if(cont_frames):
        for i in range(iters):
            for j in range(acc_len):
                for k in range(vec_len):
                    if((j==(acc_len-1)) and (k==(vec_len-1))):
                        dut.new_acc.value = 1
                    else:
                        dut.new_acc.value = 0
                    dut.din1_re.value = int(data[0][j][k][i])
                    dut.din1_im.value = int(data[1][j][k][i])
                    dut.din2_re.value = int(data[2][j][k][i])
                    dut.din2_im.value = int(data[3][j][k][i])
                    dut.din_valid.value = 1
                    await ClockCycles(dut.clk, 1)
    #else:
        ###TODO


async def read_data(dut, gold, dout_width, dout_pt, thresh):
    await FallingEdge(dut.dout_valid)
    await ClockCycles(dut.clk, 2)
    count=0
    while(count<len(gold[0])):
        valid = int(dut.dout_valid.value)
        if(valid):
            print(count)
            r11 = int(dut.r11.value)
            r12_re = int(dut.r12_re.value)
            r12_im = int(dut.r12_im.value)
            r22 = int(dut.r22.value)
            r11,r22,r12_re,r12_im = two_comp_unpack(np.array([r11,r22,r12_re,r12_im])
                                                , dout_width, dout_pt)
            print('r11  : \t rtl:%.2f \t gold:%.2f' %(r11, gold[0][count].real))
            print('r22: \t rtl:%.2f \t gold:%.2f' %(r22, gold[1][count].real))
            print('r12: \t rtl:%.2f + %.2f j \t gold:%.2f + %.2f j \n' 
                    %(r12_re, r12_im, gold[2][count].real, gold[2][count].imag))
            assert(np.abs(r11-gold[0][count].real)<thresh), "Error R11"
            assert(np.abs(r22-gold[1][count].real)<thresh), "Error R22"
            assert(np.abs(r12_re-gold[2][count].real)<thresh), "Error R12 real"
            assert(np.abs(r12_im-gold[2][count].imag)<thresh), "Error R12 imag"
            count +=1
        await ClockCycles(dut.clk, 1)

