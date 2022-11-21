import numpy as np


def create_signal(sig, lo_freq, amp_sig, fft_len, fs):
    """
    Create time domain signal from the S parameters
    """
    freq = sig[:,0] - lo_freq
    amp = sig[:,1]
    phase = sig[:,2]

    t = np.arange(fft_len)
    fft_ch = np.abs(np.around(freq/fs*fft_len)).astype(int)
    data = np.zeros([len(freq), fft_len])
    for i in range(len(freq)):
        data[i,:] = amp_sig*amp[i]*np.sin(2*np.pi*freq[i]/fs*t+np.deg2rad(phase[i]))
    return data


def calibrate_weights(cal1, cal2, lo_freq, amp_sig, fft_len, fs):
    freq = cal1[:,0]-lo_freq
    amp1 = cal1[:,1] 
    amp2 = cal2[:,1]
    phase1 = cal1[:,2]
    phase2=cal2[:,2] 

    cal1_sig = create_signal(cal1, lo_freq, amp_sig, fft_len, fs)
    cal2_sig = create_signal(cal2, lo_freq, amp_sig, fft_len, fs)

    cal1_spect = np.fft.fft(cal1_sig, axis=1)
    cal2_spect = np.fft.fft(cal2_sig, axis=1)
    a2 = cal1_spect*np.conj(cal1_spect)
    b2 = cal2_spect*np.conj(cal2_spect)
    ab = cal1_spect*np.conj(cal2_spect)
    for i in range(cal1_sig.shape[0]):
        ind = np.argmax(a2[i,:])


     


    t = np.arange(fft_len)
    a2 = np.zeros([fft_len/2,len(freq)], dtype=complex)
    b2 = np.zeros([fft_len/2,len(freq)], dtype=complex)
    ab = np.zeros([fft_len/2, len(freq)], dtype=complex)
    usb_const = np.ones(fft_len/2, dtype=complex)*1j
    lsb_const = np.ones(fft_len/2, dtype=complex)*1j
    for i in range(len(freq)):
        sig1 = amp_sig*amp1[i]*np.sin(2*np.pi*freq[i]/fs*t+np.deg2rad(phase1[i]))
        sig2 = amp_sig*amp2[i]*np.sin(2*np.pi*freq[i]/fs*t+np.deg2rad(phase2[i]))
        spec1 = fft(sig1)
        spec2 = fft(sig2)
        a2[:,i] = spec1[:fft_len/2]*np.conj(spec1[:fft_len/2])
        b2[:,i] = spec2[:fft_len/2]*np.conj(spec2[:fft_len/2])
        ab[:,i] = spec1[:fft_len/2]*np.conj(spec2[:fft_len/2])
    for j in range(int(len(freq)/2)):
        ind = np.argmax(a2[:,j])
        a2_lsb = a2[ind,j];
        b2_lsb=b2[ind,j];
        ab_lsb=ab[ind,j]
        a2_usb = a2[ind,len(freq)-1-j];
        b2_usb=b2[ind,len(freq)-1-j];
        ab_usb=ab[ind,len(freq)-1-j]
        usb_const[ind] = -1*ab_lsb/b2_lsb
        lsb_const[ind] = -1*np.conj(ab_usb)/a2_usb
    return [usb_const, lsb_const]


def evaluate_data(test1, test2, usb_w,lsb_w, lo_freq,amp_sig,fft_len,fs):
    """idem as calibrate weights..
        usb_w, lsb_w = weights of the calibrated signal (ideal ones are 0+j)
    """
    freq = test1[:,0]-lo_freq
    amp1 = test1[:,1]
    amp2 = test2[:,1]
    phase1 = test1[:,2]
    phase2=test2[:,2] 
    index = np.around(freq/fs*fft_len)
    index = np.abs(index).astype(int)
    t = np.arange(fft_len)
    usb_data = np.zeros(len(freq))
    lsb_data = np.zeros(len(freq))
    for i in range(len(freq)):
        sig1 = amp_sig*amp1[i]*np.sin(2*np.pi*freq[i]/fs*t+np.deg2rad(phase1[i]))
        sig2 = amp_sig*amp2[i]*np.sin(2*np.pi*freq[i]/fs*t+np.deg2rad(phase2[i]))
        spec1 = fft(sig1)
        spec2 = fft(sig2)
        usb = spec1[:fft_len/2]+usb_w*spec2[:fft_len/2]
        lsb = spec2[:fft_len/2]+lsb_w*spec1[:fft_len/2]
        #ipdb.set_trace()
        usb_data[i] = 20*np.log10(np.abs(usb[index[i]])+1)
        lsb_data[i] = 20*np.log10(np.abs(lsb[index[i]])+1)
    srr_lsb = lsb_data[:len(freq)/2]-usb_data[:len(freq)/2]
    srr_usb = usb_data[len(freq)/2+1:]-lsb_data[len(freq)/2+1:]
    return [usb_data, lsb_data, srr_lsb, srr_usb]


if __name__ == '__main__':
    fs = 24.5
    amp_sig = 4.5
    fft_size = 512

    lo = 79.2

    ###
    ideal_w = np.ones(fft_size/2)*1j
    
    ##these files are S parameters of a simulation
    cal1 = np.loadtxt('../data/cal_data_if1.txt', skiprows=2)
    cal2 = np.loadtxt('../data/cal_data_if2.txt', skiprows=2)

    test1 = np.loadtxt('../data/test_data_if1.txt', skiprows=2)
    test2 = np.loadtxt('../data/test_data_if2.txt', skiprows=2)

    usb_w, lsb_w = calibrate_weights(cal1,cal2,lo,amp_sig,fft_size,fs)
   
    cal_usb_ideal, cal_lsb_ideal, cal_srr_lsb_ideal, cal_srr_usb_ideal = evaluate_data(cal1,cal2,
            ideal_w,ideal_w, lo, amp_sig, fft_size,fs)
    
    cal_usb, cal_lsb, cal_srr_lsb, cal_srr_usb = evaluate_data(cal1,cal2,usb_w,
            lsb_w, lo, amp_sig, fft_size,fs)

    test_usb, test_lsb, test_srr_lsb, test_srr_usb = evaluate_data(test1,test2,
            usb_w,lsb_w, lo, amp_sig, fft_size,fs)

    test_usb_ideal, test_lsb_ideal, test_srr_lsb_ideal, test_srr_usb_ideal = evaluate_data(test1,
            test2,ideal_w,ideal_w, lo, amp_sig, fft_size,fs)

