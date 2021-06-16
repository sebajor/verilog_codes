This module should work rigth for the first layer, because we could
have several perceptrons runing in parallel and receiving samples
in each clock cycle.

But, for the next layers you got a lot of free time because the 
logic is just waiting until the previous layer finish its task, 
so we could multiplex in time one neuron using differnt weights/bias
and saving everything in a memor/bias
and saving everything in a memory.
