import numpy as np
import matplotlib.pyplot as plt


def frb_curve(DM, f1, f2, n_samp=8192):
    """
     inputs:
        DM in pc*cm**3
        f1, f2 in mhz
     outputs:
        f in MHz
        t in seconds 
    """
    #normalizo todo, con accumulacion se debiese poder
    #ti = 4.149*10**3*DM*f1**(-2)
    #tf = 4.149*10**3*DM*f2**(-2)
    ti = f1**(-2)
    tf = f2**(-2)
    t = np.linspace(ti,tf,n_samp)
    #f = np.sqrt(4.149*10**3*DM/t)
    f = np.sqrt(1/t)
    #t = 4.149*10**3*DM*f**(-2)
    return [t-t[-1],f]


def frb_values(n_chann=64):
    curve = np.zeros([n_chann, n_chann])
    t,f = frb_curve(1, 1800,1200,n_chann)
    f_bin = 600./n_chann
    bins = np.round((f-1200)/f_bin)
    mask = np.where(bins>n_chann-1)
    bins[mask] = n_chann-1
    #revisar!!!!
    for i in range(n_chann):
        curve[i,int(bins[i])] = 1
    return curve


n_chann=64
curve = frb_values(n_chann)
delay = np.zeros(n_chann)
prev = 63
for i in range(n_chann):
    aux = np.where(curve[:,i]==1)[0]
    if(len(aux)==0):
        delay[i] = prev
    else:
        delay[i] = aux[0]
        prev = aux[0]
    
delay = (65-delay).astype(int)[::-1]    #reorder
