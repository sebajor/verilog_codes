import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import numpy as np
import uesprit
from scipy.fftpack import fft


def two_comp_pack(values, n_bits, n_int):
    """ Values are a numpy array witht the actual values
        that you want to set in the dut port
        n_bits: number of bits
        n_int: integer part of the representation
    """
    bin_pt = n_bits-n_int
    quant_data = (2**bin_pt*values).astype(int)
    ovf = (quant_data>2**(n_bits-1)-1)&(quant_data<2**(n_bits-1))
    if(ovf.any()):
        raise "Cannot represent one value with that representation"
    mask = np.where(quant_data<0)
    quant_data[mask] = 2**(n_bits)+quant_data[mask]
    return quant_data


def two_comp_unpack(values, n_bits, n_int):
    """Values are integer values (to test if its enough to take
    get_value_signed to obtain the actual value...
    """
    bin_pt = n_bits-n_int
    mask = values>2**(n_bits-1)-1 ##negative values
    out = values.copy()
    out[mask] = values[mask]-2**n_bits
    out = 1.*out/(2**bin_pt)
    return out


def create_clean_data(freqs=[10], phases=[30], acc_len=5, vec_len=64,snr=40, xspace=0.05):
    data = uesprit.multi_source(freqs=freqs, phases=phases, length=acc_len*vec_len, dft_len=vec_len, x_space=xspace)
    data = uesprit.add_noise(data, snr)
    dat0 = data[0,:].reshape([acc_len,vec_len])
    dat1 = data[1,:].reshape([acc_len,vec_len])
    spec0 = fft(dat0, axis=1)
    spec1 = fft(dat1, axis=1)
    return [spec0, spec1]

@cocotb.test()
async def scalar_uesprit_test(dut, acc_len=5, vec_len=64, din_width=16,
            din_pt=14, dout_width=32, dout_pt=16, xspace=0.01):
    freqs = np.ones(20)*10
    phases = np.linspace(-60, 60, 13)
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    dut.new_acc <=0
    dut.din1_re<=0; dut.din1_im<=0;
    dut.din2_re<=0; dut.din2_im<=0;
    dut.din_valid<=0
    await ClockCycles(dut.clk,1)
    spec0, spec1 = create_clean_data(freqs=[freqs[0]], phases=[phases[0]],acc_len=acc_len, vec_len=vec_len,xspace=xspace)
    spec0 = 1.*spec0/(np.max([np.max(spec0.real), np.max(spec0.imag)]))
    spec1 = 1.*spec1/(np.max([np.max(spec1.real), np.max(spec1.imag)]))
    r11,r22,r12_re,r12_im = await write_data(dut,spec0, spec1, din_width,din_pt,dout_width, dout_pt)
    for i in range(1, len(phases)):
        spec0, spec1 = create_clean_data(freqs=[freqs[i]], phases=[phases[i]],acc_len=acc_len, vec_len=vec_len,xspace=xspace)
        spec0 = 1.*spec0/(np.max([np.max(spec0.real), np.max(spec0.imag)]))
        spec1 = 1.*spec1/(np.max([np.max(spec1.real), np.max(spec1.imag)]))
        r11,r22,r12_re,r12_im = await write_data(dut,spec0, spec1, din_width,din_pt,dout_width, dout_pt)
        r11 = r11#np.sum(r11)
        r12 = r12_re#np.sum(r12_re)
        r22 = r22#np.sum(r22)
        #norm = np.max([np.max(r11), np.max(r12), np.max(r22)])
        #r11 = r11/norm; r12 = r12/norm; r22 = r22/norm
        doa, mu, l1,l2 = uesprit.uesprit_la(r11,r12,r22,x_space=xspace, freq=10)
        print("iter %i doa:%.4f"%((i-1), doa))
    
    """
    for i in range(len(r11)):
        print(i)
        print("r11= gold:%.4f\t hdl:%.4f"%(np.sum(gold_r11), r11[i]))
        print("r22= gold:%.4f\t hdl:%.4f"%(np.sum(gold_r22), r22[i]))
        print("r12_re= gold:%.4f\t hdl:%.4f"%(np.sum(gold_r12).real, r12_re[i]))
        print("r12_im= gold:%.4f\t hdl:%.4f"%(np.sum(gold_r12).imag, r12_im[i]))
        print("\n")

    """






async def write_data(dut, dat1, dat2, din_width, din_pt, dout_width, dout_pt):
    """
        dat: [acc_len, vec_len]
    """
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    acc_len, vec_len = dat1.shape
    #
    dut.new_acc<=1
    r11 = []; r22=[]; r12_re=[]; r12_im=[]
    for i in range(acc_len):
        din1re = two_comp_pack(dat1[i,:].real, din_width, din_int)
        din1im = two_comp_pack(dat1[i,:].imag, din_width, din_int)
        din2re = two_comp_pack(dat2[i,:].real, din_width, din_int)
        din2im = two_comp_pack(dat2[i,:].imag, din_width, din_int)
        for j in range(vec_len):
            dut.din1_re <= int(din1re[j])
            dut.din1_im <= int(din1im[j])
            dut.din2_re <= int(din2re[j])
            dut.din2_im <= int(din2im[j])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            dut.new_acc <=0;
            valid = int(dut.dout_valid.value)
            if(valid):
                r11_val = np.array(int(dut.r11.value))
                r22_val = np.array(int(dut.r22.value))
                r12_re_val = np.array(int(dut.r12_re.value))
                r12_im_val = np.array(int(dut.r12_im.value))
                r11.append(r11_val)
                r22.append(r22_val)
                r12_re.append(r12_re_val)
                r12_im.append(r12_im_val)
    out_r11 = np.array(r11)
    out_r22 = np.array(r22)
    out_r12_re = np.array(r12_re)
    out_r12_im = np.array(r12_im)
    #convert data
    out_r11 = out_r11/(2.**dout_pt)
    out_r22 = out_r22/(2.**dout_pt)
    out_r12_re = two_comp_unpack(out_r12_re, dout_width, dout_int)
    out_r12_im = two_comp_unpack(out_r12_im, dout_width, dout_int)

    out_vals = [out_r11, out_r22, out_r12_re, out_r12_im]
    return out_vals
