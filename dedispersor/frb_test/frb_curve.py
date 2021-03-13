import numpy as np
from astropy import units as u
from astropy import constants as cte
import matplotlib.pyplot as plt
import sys

sys.path.insert(1, '/home/seba/Workspace/test_code/machines/awg_chino')

import fygen.fygen as fygen

def frb_curve(DM, f1, f2, n_samp=8192):
    """
     inputs:
        DM in pc*cm**3
        f1, f2 in mhz
     outputs:
        f in MHz
        t in seconds 
    """
    ##wrong!!! the t must be linear!
    #ti = 4.149*10**3*DM*f1**(-2)
    #tf = 4.149*10**3*DM*f2**(-2)
    ti = f1**(-2)
    tf = f2**(-2)
    t = np.linspace(ti,tf,n_samp)
    #f = np.sqrt(4.149*10**3*DM/t)
    f = np.sqrt(1./t)
    #t = 4.149*10**3*DM*f**(-2)
    return [t-t[-1],f]


#def vco(t,f, f_offset=1200):
    """
    zx95-3360R-S+
    retunrs the sampling rate and
    the voltage asociated to a certain frec
    we take a linear approx to the v_tune-f curve in the range
    2315-3239mhz 
    
    f = f+f_offset # add 1.2G to be in the range ie we have to downconvert this
    v = (12.-3)/(3238-2315)*(f-2315)+3
    #fs = 1./(t[0]-t[1])
    v_off = min(v)
    v_max = max(v)
    fs = 1./t[0]
    v_norm = (v-v_off)/(v_max-v_off)
    return [v, v_norm, fs, v_off, v_max]
    """
def vco(t,f, f_offset=800):
    """
    CVCO55CW-1600-3200
    retunrs the sampling rate and
    the voltage asociated to a certain frec
    we take a linear approx to the v_tune-f curve in the range
    0.5-10V --> 1.46-2.5GHz
    

   """ 
    f = f+f_offset # 
    #v = (12.-3)/(3238-2315)*(f-2315)+3
    v = (10-0.5)/(2500-1460)*(f-2500)+10
    #fs = 1./(t[0]-t[1])
    v_off = min(v)
    v_max = max(v)
    fs = 1./t[0]
    v_norm = (v-v_off)/(v_max-v_off)
    return [v, v_norm, fs, v_off, v_max]
  


def create_curve(DM, f1, f2,n_samp=8192,f_offset=800, port='/dev/ttyUSB0', chann=0):
    """we have to handle the power output..
    i have to check the actual capabilities of the 
    awg, it seems that the max voltage is 20
    """
    t,f = frb_curve(DM, f1, f2, n_samp=n_samp)
    v,v_norm, fs, v_off, v_max = vco(t,f,f_offset=f_offset)
    fy = fygen.FYGen(serial_path=port)
    fy.set_waveform(1, values=v_norm[::-1])        ##checked
    fy.set(channel=chann, wave='arb1', freq_hz=abs(fs), volts=2*(v_max-v_off), offset_volts=v_off, enable=True)  ##check!!
    
    return [v,v_norm,f,t,fs,v_off,v_max]



