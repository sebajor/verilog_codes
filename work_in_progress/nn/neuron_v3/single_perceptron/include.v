`ifndef _CAST_
    `include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/signed_cast/signed_cast.v"
    `define _CAST_
`endif

`ifndef _MULT_
    `include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/parallel_mult/parallel_mult.v"
    `define _MULT_
`endif

`ifndef _ACC_
    `include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/accumulator/acc.v"
    `define _ACC_
`endif

`ifndef _ACT_
    `include "/home/seba/Workspace/verilog_codes/dev/nn/neuron_v3/activation/activation.v"
    `define _ACT_
`endif

    
