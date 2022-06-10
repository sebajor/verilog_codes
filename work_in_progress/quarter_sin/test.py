import numpy as np
import matplotlib.pyplot as plt

##example of how to calculate the data

t = np.arange(1024)
complete = np.sin(2*np.pi*201*t/1024.)


frac = complete[:257]

first = frac[:256]
second = frac[::-1][:256]
third = -frac[:256]
fourth = -frac[::-1][:256]

quarter = np.hstack([first, second, third, fourth])
plt.plot(complete-quarter)
plt.grid()
plt.ylabel('Quarter error')
plt.show()

##as when we write it verilog we will need the indeces, and use a counter

out = []
counter =0
#1st quarter
while(counter < 256):
    out.append(frac[counter])
    counter +=1
out.append(frac[256])

counter=255
while(counter > 0):
    out.append(frac[counter])
    counter -=1
#here we skip the first sample

counter=0
while(counter<256):
    out.append(-frac[counter])
    counter +=1

out.append(-frac[256])
counter = 255
while(counter>0):
    out.append(-frac[counter])
    counter -=1

plt.plot(complete-out)
plt.grid()
plt.ylabel('Quarter error')
plt.show()






