import numpy as np
#import ipdb
import copy

#
#Im going to imitate the 
#

class pfb_lane_sim():
    def __init__(self, coeff_file, stream_number, buffer_size):
        """
        the buffer size must be equal to the n_coeffs!!!!
        """
        ##the axis are number streams, taps, coeff values
        coeffs = np.load(coeff_file)
        self.n_streams, self.n_taps, self.n_coeffs = coeffs.shape
        self.coeffs = coeffs[stream_number,:,:]
        self.buffer_size = buffer_size#self.n_coeffs-3   ##2**(M*P)-bram_latency
        #self.coeffs = self.coeffs[:,::-1]    
        self.coeffs = self.coeffs[::-1,:]    
        self.buffers = np.zeros([self.n_taps, self.buffer_size])
        ##just to match the simulation
        self.coeffs = np.roll(self.coeffs, 2, axis=1) #?
    
    def compute_outputs(self,data):
        """
        I think the valid output starts at (taps-1)*(pfb_size/lanes)+2
        """
        output = np.zeros(len(data))
        deb = np.zeros((len(data), self.n_taps, self.buffer_size))
        deb2 = np.zeros((len(data), self.n_taps))
        for i in range(len(data)):
            ##make all the shiftings
            self.buffers[0,:] = np.roll(self.buffers[0,:], 1)
            dout_tap = self.buffers[0,0].copy()
            self.buffers[0,0] = data[i]
            for j in range(1,self.n_taps):
                self.buffers[j,:] = np.roll(self.buffers[j,:], 1)
                aux = self.buffers[j,0].copy()
                self.buffers[j,0] = dout_tap
                dout_tap = aux
            ##dont ask me why
            deb[i,:,:] = self.buffers
            deb2[i,:] = self.coeffs[:,0]
            output[i] = np.sum(self.coeffs[:,0]*self.buffers[:,0])
            self.coeffs = np.roll(self.coeffs, -1, axis=1) #?
        return output, deb, deb2


def pfb_fir_frontend(x, win_coeffs, M, P):
    W = int(x.shape[0] / M / P)
    x_p = x.reshape((W*M, P)).T
    h_p = win_coeffs.reshape((M, P)).T
    x_summed = np.zeros((P, M * W - M))
    for t in range(0, M*W-M):
        x_weighted = x_p[:, t:t+M] * h_p
        x_summed[:, t] = x_weighted.sum(axis=1)
    return x_summed.T


