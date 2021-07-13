Each neuron accepts parallel streams of data and uses dsp48 per stream, per 
neuron. 
For example if I use 4 neuron with 4 parallel streams we are using 4x4 dsp48.

This should give a good interface with the first layer of the system, 
then you could multiplex the multiplier resources using brams to save the
ouptuts of the previous layers and the weigths.
For that look at the other implementation, neuron_multiplexed
 
