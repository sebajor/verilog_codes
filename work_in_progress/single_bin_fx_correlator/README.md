# Single bin XF correlator

This module just calculate a single frequency bin of a DFT via the standard definition for two inputs and calculate the correlation and auto-correlation betweeen them.
Usefull for applications that need to calculate the phase-magnitude difference of a common signal with known frequency and you dont want to use an FFT.
The implementation has an axi-lite interface to upload the twiddle factors to the bram.

For a sliding window implementation look at the MSDFT correlator.
