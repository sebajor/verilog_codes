https://opalkelly.com/products/szg-adc-ltc226x/

https://github.com/opalkelly-opensource/design-resources/tree/main/ExampleProjects/ADC_Sample/XEM8320

Brain example with the ltc2264 https://github.com/SYZYGYfpga/brain-sample-hdl/tree/master/pod-adc-ltc2264

--------------------------------------------------------------------------------------
Each channel output 2bits at the time (2-lane mode) at lower sample rates there is a one bit channel option (1-lane mode).
You can choose a lot of programming modes via the SPI mode.

The timing of the data is given by
serial data                  serial data rate   DCO freq    FR  
    2-lanes, 16 bit             8xfs            4xfs        fs
    2-lanes, 14 bit             7xfs            3.5xfs      0.5fs
    2-lanes, 12 bit             6xfs            3xfs        fs
    1-lane,  16 bit             16xfs           8xfs        fs
    1-lane,  14 bit             14xfs           7xfs        fs  
    1-lane,  12 bit             12xfs           6xfs        fs



To start spi mode PAR/SER should be tied to GND. Data is written with a 16bit serial word.
Data transfer starts when CS is take down, the data on SDI is latched at the first 16 rising edges of SCK (the SCK rising after the first 16 are ignored), the data transfer ends when CS is taken high.

The first bit is R/W bit. The next bits are the address of the register (A6:A0), the final eight bits are the register data (D7:D0)
If serial programming is used then the first command should be a reset that put all the registers at 0.




--------------------------------------------------------------------------------------
ADC datasheet:https://www.analog.com/en/products/ltc2268-14.html#product-overview

Pins:

Ain1+-=Channel 1 analog input
Vcm1= Common bias output
refh=ADC high reference
refl=ADC low reference
Vcm2=common bias output 
Ain2+-=Channe 2 analog input
Vdd=1.8 power supply
ENC+=Encode input, conversion start at rising edge
ENC-=Encode input, conversion start at falling edge
CS=In serial programming mode, chip select
SCK=In serial programming mode, serial interface clock
SDI=In serial programming mode, serial data input
GND
OGND=output driver gnd, shorted to gnd plane
OVDD=output dirver, shorted to gnd
SDO=In serial programming mode, the data output
PAR/SER=Programming mode selection pin, when low enable serial programming mode.
VREF=ref output
SENSE= Reference programming pin. When Vdd select internal reference and +-1V range. When connected to GND use internal reference and +-0.5V range. If the voltage is between 0.625V and 1.3V is set to external refernece and the input range is in +-0.8xVSENSE.
OUT2B-/OUT2B+, OUT2A-/OUT2A+=Serial data outputs for channel2. In 1-lane output mode only out2A are used.
FR-/FR+=Frame start outputs
OUT2B-/OUT2B+, OUT2A-/OUT2A+=Serial data outputs for channel1. In 1-lane output mode only out1A are used.

-------------------------------------------------------------------------------------
the opalkelly peripheral has the following table

pin     signal name     schematic net
5       D0P             OUT1A+    
7       D0N             OUT1A-
6       D1P             FR+
8       D1N             FR-
9       D2P             OUT1B+
11      D2N             OUT1B-
10      D3P             OUT2A+
12      D3N             OUT2A-
13      S8              SDO
14      D5P             OUT2B+
16      D5N             OUT2B-
15      S10             CS_B
17      S12             SCLK
19      S14             SDI
33      P2C_CLKp        DCO+
35      P2C_CLKn        DCO-
34      C2P_CLKp        ENC+
36      C2P_CLKn        ENC-

