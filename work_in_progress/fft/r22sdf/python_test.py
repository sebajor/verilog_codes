import numpy as np
import itertools

bf1_test = False
bf2_test = False
fft_complete = True

def bit_reversal_indices(n):
    num_bits = int(np.log2(n))
    out = np.array([int(f'{i:0{num_bits}b}'[::-1], 2) for i in range(n)])
    return out

def fft_bit_reversed(x):
    n = len(x)
    fft_out = np.fft.fft(x)
    bit_ind = bit_reversal_indices(n)
    out = fft_out[bit_ind]
    return out




class BF_I():
    def __init__(self, buffer_line):
        self.buffer = [0]*buffer_line
        self.state = 0
        self.counter = 0
        self.dout = 0

    def process(self, din):
        out_buffer = self.buffer.pop()
        self.counter+=1
        if(self.state == 0):
            self.buffer.insert(0, din)
            self.dout = out_buffer
        else:
            self.buffer.insert(0, out_buffer-din)
            self.dout = out_buffer+din
        if(self.counter== len(self.buffer)):
            self.state = not self.state
            self.counter = 0





class BF_II():
    def __init__(self, buffer_line):
        self.buffer = [0]*buffer_line
        self.state = 0
        self.counter = 0
        self.dout =0 

    def process(self, din):
        out_buffer = self.buffer.pop()
        self.counter += 1
        if(self.state==0):
            self.buffer.insert(0,din)
            self.dout = out_buffer
        elif(self.state ==1):
            self.buffer.insert(0, out_buffer-din)
            self.dout = out_buffer+din
        elif(self.state ==2):
            self.buffer.insert(0, (out_buffer.real-din.imag)+1j*(out_buffer.imag+din.real))
            self.dout = (out_buffer.real+din.imag)+1j*(out_buffer.imag-din.real)

        if(self.counter == len(self.buffer)):
            self.state = 1
        elif(self.counter == 2*len(self.buffer)):
            self.state = 0
        elif(self.counter ==3*len(self.buffer)):
            self.state = 2
        elif(self.counter ==4*len(self.buffer)):
            self.state = 0
            self.counter =0 




if __name__ == '__main__':
    if(bf1_test):
        ## the first buffer len is not valid.. then it output a[n]+a[N-n] for N/2 cycles, where N is 
        ##2 times the buffer len. Then after that it returns a[n]-a[N-n] for the next N/2 cycles..
        buffer_size = 32
        test_data = np.random.random(8*buffer_size)
        out = []
        bf1 = BF_I(buffer_size)
        for dat in test_data:
            bf1.process(dat)
            out.append(bf1.dout)
        
        gold = test_data.reshape((-1, buffer_size))
        z1 = gold[::2,:]+gold[1::2,:]
        z2 = gold[::2,:]-gold[1::2,:]
        gold_out = np.hstack((z1,z2)).flatten()
        out = np.array(out)
        assert (out[buffer_size:] == gold_out[:len(out)-buffer_size]).all()


    if(bf2_test):
        ##the first buffer len is not valid.. then it outputs a[n]+a[N-n] for N/2 cycles,
        ##then it outputs a[n]-a[N-n], then the following its a[n]+a[N-n] again and the last 
        ##is -1j*a[n]-a[N-n]
        buffer_size = 32
        test_data = np.random.random(8*buffer_size)
        out = []
        state = []
        bf2 = BF_II(buffer_size)
        for dat in test_data:
            bf2.process(dat)
            out.append(bf2.dout)
            state.append(bf2.state)

        gold = test_data.reshape((-1, buffer_size))
        z1 = gold[::4,:]+gold[1::4,:]
        z2 = gold[::4,:]-gold[1::4,:]
        z3 = gold[2::4,:]+(-1j)*gold[3::4,:]
        z4 = gold[2::4,:]-(-1j)*gold[3::4,:]
        gold_out = np.hstack((z1,z2,z3,z4)).flatten()
        out = np.array(out)
        assert (out[buffer_size:] == gold_out[:len(out)-buffer_size]).all()

        
    if(fft_complete):
        ##well do a 16 points FFT.. this is BF1(8)-> BF2(4) -> twiddle mult ->BF1(2) -> BF2(1)
        ##the twiddle factors are decomposed in 4 types, each one of N/4. 
        ##the first are just 1,
        ##the second is W_n**(2*i)
        ##the third is W_n**(i)
        ##the forth is W_n**(3*i)
        fft_size = 16
        test_data = np.random.random(8*16)
        stage1 = BF_I(8)
        stage2 = BF_II(4)
        #stage3 is the twiddle multiplication
        stage4 = BF_I(2)
        stage5 = BF_II(1)
        W_n = np.exp(-1j*2*np.pi/fft_size)
        twiddle_factors = np.array([ 1,1,1,1,
                                1, W_n**2, W_n**4, W_n**6,
                                1, W_n**1, W_n**2, W_n**3,
                                1, W_n**3, W_n**6, W_n**9
            ])
        out_stage1 = []
        for dat in test_data:
            stage1.process(dat)
            out_stage1.append(stage1.dout)
        out_stage1 = np.array(out_stage1)[8:]
        
        out_stage2 = []
        for dat in out_stage1:
            stage2.process(dat)
            out_stage2.append(stage2.dout)
        out_stage2 = np.array(out_stage2)[4:]
        
        out_stage3 = []
        for dat, twid in zip(out_stage2, itertools.cycle(twiddle_factors)):
            out_stage3.append(dat*twid)
        out_stage3 = np.array(out_stage3)

        out_stage4 = []
        for dat in out_stage3:
            stage4.process(dat)
            out_stage4.append(stage4.dout)
        out_stage4 = np.array(out_stage4)[2:]

        out_stage5 = []
        for dat in out_stage4:
            stage5.process(dat)
            out_stage5.append(stage5.dout)

        out_stage5 = np.array(out_stage5)[1:]
        completed_ffts = len(out_stage5)//fft_size
        ffts = out_stage5[:completed_ffts*fft_size].reshape((-1, fft_size))
        gold_natural = np.fft.fft(test_data.reshape((-1, fft_size)), axis=1)
        bit_ind = bit_reversal_indices(fft_size)
        gold = gold_natural[:,bit_ind]

        ##we compare this 
        threshold = 1e-9
        assert (np.abs(gold.real[:ffts.shape[0],:]-ffts.real)<threshold).all()
        assert (np.abs(gold.imag[:ffts.shape[0],:]-ffts.imag)<threshold).all()

