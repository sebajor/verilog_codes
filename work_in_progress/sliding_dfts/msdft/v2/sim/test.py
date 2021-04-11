import numpy as np
import matplotlib.pyplot as plt
import msdft

lenght = 20000
dft_size = 4*1024
freq = 333
amp1 = 10
phase1 = 150
amp2 = 30
phase2 = 220
snr1 = 20
snr2 = 50

pow_db, ang, gold_pow, gold_ang = msdft.corr_test(lenght, dft_size, freq,
        amp1, phase1, amp2, phase2, snr1, snr2)

print('gold pow: %.4f \t gold phase: %.4f' %(gold_pow, gold_ang))
print('msdft avg pow: %.4f \t msdft avg phase: %.4f' %(np.mean(pow_db[-1024:]), np.mean(ang[-1024:])))
fig = plt.figure()
ax1 = fig.add_subplot(121)
ax1.set_title("Pow diff")
ax1.grid()
ax2 = fig.add_subplot(122)
ax2.set_title("Ang diff")
ax2.grid()

ax1.plot(pow_db)
ax2.plot(ang)

plt.show()

