import numpy as np
import h5py, cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack


@cocotb.test()
async def rfi_power_test(dut, iters=2**14, din_width=9, din_point=8,
        dout_width=16, dout_point=8, acc_len=20, filename='../tone.hdf5',
        shift=6, thresh=0.5):
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    dut.sig_re.value =0;    dut.sig_im.value=0;
    dut.ref_re.value =0;    dut.ref_im.value=0;
    dut.din_valid.value=0;  dut.sync_in.value =0
    dut.acc_len.value=acc_len
    dut.cnt_rst.value =0

    await ClockCycles(dut.clk,3)
    dut.cnt_rst.value = 1;
    await ClockCycles(dut.clk, 1)
    dut.cnt_rst.value = 0
    await ClockCycles(dut.clk,3)

    #get the data from the file
    f = h5py.File(filename, 'r')
    adc0 = np.array(f['adc0'])/2.**(15-shift)
    adc1 = np.array(f['adc1'])/2.**(15-shift)
    adc3 = np.array(f['adc3'])/2.**(15-shift)

    beam = (adc0+adc1).T.flatten()
    rfi = adc3.T.flatten()

    beam_re = two_comp_pack(beam.real, din_width, din_point)
    beam_im = two_comp_pack(beam.imag, din_width, din_point)

    rfi_re = two_comp_pack(rfi.real, din_width, din_point)
    rfi_im = two_comp_pack(rfi.imag, din_width, din_point)

    data = [beam_re, beam_im, rfi_re, rfi_im]

    rfi_pow = rfi*np.conj(rfi)
    beam_pow = beam*np.conj(beam)

    rfi_pow = rfi_pow.reshape([-1, 2048])
    beam_pow = beam_pow.reshape([-1, 2048])


    ##CHECK!
    lim_ind = rfi_pow.shape[0]//acc_len
    rfi_pow = rfi_pow[:acc_len*lim_ind,:].T
    beam_pow = beam_pow[:acc_len*lim_ind,:].T
    
    rfi_acc = np.sum(rfi_pow.reshape([2048,-1, acc_len]), axis=2)
    beam_acc = np.sum(beam_pow.reshape([2048,-1,acc_len]), axis=2)
    gold = (rfi_acc*beam_acc).T.flatten()

    cocotb.fork(write_data(dut, data, 2048))
    rtl_data = await read_data(dut, iters, gold, dout_width, dout_point, thresh)
    np.savetxt('rtl_data.txt', rtl_data.reshape([-1,2048]))
    np.savetxt('gold_data.txt', (gold.real).reshape([-1,2048]))
    


async def write_data(dut, data, vec_len):
    dut.sync_in.value =0 
    await ClockCycles(dut.clk,1)
    dut.sync_in.value = 1
    await ClockCycles(dut.clk,1)
    dut.din_valid.value = 1
    for i in range(len(data[0])):
        dut.sig_re.value = int(data[0][i])
        dut.sig_im.value = int(data[1][i])
        dut.ref_re.value = int(data[2][i])
        dut.ref_im.value = int(data[3][i])
        if((i%vec_len==(vec_len-1))):
            dut.sync_in.value = 1
        else:
            dut.sync_in.value = 0
        await ClockCycles(dut.clk, 1)

async def read_data(dut, iters, gold, dout_width, dout_point, thresh):
    count =0
    data = np.zeros(iters)
    while(count < iters):
        warn =  int(dut.warning.value)
        assert (warn ==0), 'Warning!!'
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = np.array(int(dut.dout.value))
            dout = two_comp_unpack(dout, dout_width, dout_point)
            print('rtl: %.4f  gold:%.4f' %(dout, gold[count]))
            assert (np.abs(dout-gold[count])< thresh)
            data[count] = dout
            count +=1
        await ClockCycles(dut.clk, 1)
    return data
