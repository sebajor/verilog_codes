Dram to 10gbe ethernet read converter.

Module to interface the ROACH2 dram controller with the 10Gbe module.
It reads frames of 288bits, packetize into 256 bits and send them 
using the 10Gbe.

For that we use a fifo to store the burst from the dram, then translate 
to the 255 and face the 10Gbe.


