import sim_data
import matplotlib.pyplot as plt
import numpy as np
from scipy.fftpack import fft

#hiperparameters
n_antennas = 2      #number of antennas (in this script we only play with one)
x_space = 0.001     #space between antennas
freq = 150         #normalized frequency ie c=1
ang = 55            #deg
length = 1024       #signal lenght
snr = 60

np.random.seed(10)

clean_sig = sim_data.adc_data(n_antennas,x_space,freq,ang,length)
data = sim_data.add_noise(clean_sig, snr)

data = data/np.max(np.abs(data))

##clasic unitary esprit
## follow the notation given in zoltowski1996

## symmeteric and antisymmetric matrix multiplication
#y1 = data[0,:]*1+data[1,:]*1j
#y2 = data[0,:]*1-data[1,:]*1j

#diego..
y1 = data[0,:]+data[1,:]
y2 = data[0,:]-data[1,:]
y2 = y2.imag-1j*y2.real


#covariance matrix
R11 = np.mean(y1*np.conj(y1))
R12 = np.mean(y1*np.conj(y2))
R22 = np.mean(y2*np.conj(y2))
R21 = np.conj(R12)

#diego
#R11 = np.mean(y1.real*y1.real+y1.imag*y1.imag)
#R12 = np.mean(y1.real*y2.real+y1.imag*y2.imag)
#R22 = np.mean(y2.real*y2.real+y2.imag*y2.imag)

r11 = R11.real
r12 = R12.real
r21 = R12.real
r22 = R22.real

#r11 = np.abs(R11)
#r12 = np.abs(R21)
#r21 = r12
#r22 = np.abs(R22)

#now we need to solve the eigenvalue problem of re[Rxx]
#(r11-val)(r22-val)-r12*r21 = 0
# val**2-(r11+r22)val+(r11*r22)-r12*r21 = 0
##r11+r22+sqrt((r11-r22)**2-4*(r12**2))

lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2

"""
r11*x+r12*y = lamb*x    ---> (r11-lamb)x = -r12*y
r21*x+r22*y = lamb*y    ---> (r22-lamb)y = -r12*x


---> ((r11-lamb)/r12)x = -y  (vector propio!) 

"""


#Take arctan to obtain mu
#mu1 = 2*np.arctan(lamb1)
#mu2 = 2*np.arctan(lamb2)
mu1 = 2*np.arctan((r11-lamb1)/r12)
mu2 = 2*np.arctan((r11-lamb2)/r12)

print("mu1: %.4f" %(mu1%(2*np.pi)))


real_mu1 = mu1#%(2*np.pi)
real_mu2 = mu2%(2*np.pi)
aux1 = real_mu1/(2*np.pi*x_space*freq)
aux2 = real_mu2/(2*np.pi*x_space*freq)


#mu = 2*np.pi*x_space*freq*sin(doa_ang)
doa1 = np.rad2deg(np.arcsin(aux1))#%(2*np.pi)))
#doa2 = np.rad2deg(np.arcsin(aux2%(2*np.pi)))

print("ang: %.4f"%ang)

print("doa1: %.4f" %doa1)
#print("doa2: %.4f" %doa2)








