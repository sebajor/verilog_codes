# verilog_codes

This repository is a collection of verilog codes. Most of the codes has its own testbench and the functionality is verified using the python cosimulator cocotb.
Usually the testbench code is composed of two process that runs simoultaneously, the first one that is in charge to write the input ports of the DUT and the second process that reads the output of the DUT and compare the output signals with a golden model, if the comparation gives a difference then the simulation is stoped. As the premature stop would allows you to look at the traces and found where is the error.

As many of the codes are DSP related using cocotb allows you to check the difference in precission between a floating point and fixed point implementation.

To run the testbench you have to use the Makefiles
```
make            //run the simulation without generate traces
make WAVES=1    //run the cosimulation and generate the traces
make clean      //delete the generated subproducts of the simualtion
```

As side note, if you run make and then modify the hdl you need to clean in order to take effect in the simulation.

## Folder structure
- `arte_stuffs`     : codes for a Radio transient detector backend.[More info here](http://www.das.uchile.cl/lab_mwl/project.html).
- `axi`             : AXI and AXI lite related codes.
- `casper_utils`    : HDLs that are meanted to be used in the [CASPER](https://casper-toolflow.readthedocs.io/projects/tutorials/en/latest/index.html) enviroment. [Here](https://github.com/sebajor/simulink_models) you can found some examples.
- `cocotb_python`   : Codes for handle signed fixed point input/outputs from cocotb at bit level (I had some headaches with the standard method of cocotb).
- `dsp`             : collection of DSP modules.
- `gps`             : GPS related codes.
- `protocols`       : communication protocols (Some of these codes are modified version of open-source projects, in each the original source is pointed).
- `rfi_detector`    : A radio-frequency interference detector. [More info here](http://www.das.uchile.cl/lab_mwl/publicaciones/Tesis/RFI-detection-Engineer_thesis-Daniel_Bravo.pdf)
- `work_in_progress`: Modules that have not been completely tested.
- `xlx_templates`   : Xilinx templates. There are also some wrappers of some primitives to allow simulations.

## Requirements

The typical python packages (numpy, scipy, matplotlib, etc..) and cocotb.
For the hdl compilation we use [icarus](http://iverilog.icarus.com/) compiler, and as a waveviewer [gtkwave](https://gtkwave.sourceforge.net/)

For the axi blocks we use [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi) extension.

This is not a requirement, but I found that is quite usefull tool when developing. To code in HDL I use mostly vim with the .vimrc that is in this repository. Beside some intresting packages like [verilog_systemverilog](https://github.com/vhda/verilog_systemverilog.vim) and [systemverilog](https://github.com/nachumk/systemverilog.vim) the autocmd is set in a way that if you issue Make in the vim command mode when writing a verilog module, it will try to compile it and tells you where are the errors of your code.

## Tips when writing your own modules
- Always use `default_nettype none`, this will cause that the compiler marks as an error when using a wire/reg that is not declared. By default if you use a non-declared net the compiler will create a 1bit signal (and usually this is not what you want). Even this is a good practice when developing, when using third parties modules you should comment it because some people use this odd behaviour to not declare stuffs and if you have it active it will stop your compilation. (This always happend with xilinx modules).
- I tend to create testbench wrappers (the modules `_tb.v` that are in all folders) because when generating the traces gtkwave at the top level just shows the ports and then you could dig in the internal signals. If you dont use the toplevel tb then you will get all the internal signals of the module mixed with the ports.. and that could be messy.
- I also always create an `includes.v` that has all the require modules that are needed. You could also add them to the Makefile.
- When compiling you should import just one time the modules. In ISE is somewhat random the order of the imports so I recomend put all the requirements in one big `includes.v`, put a include guard `ifndef` (as in C) and try to include it from each module.
- Be super Carefull with the bitsize of the signed numbers when operating them. Verilog works kind of weird with the signed values, so always ensure that the you represent in full scale the output and then change the size. For example when multipliying 2 numbers of 12 bits with a bit point in the 5th bit, will give you a full scale output of 24 bits with the point in the 10th bit. So be sure that you have at least 24 bits at the output of your multiplier, then you could cast the output to other number safetly (If you dont do this you could end up with weird results). For the casting you could use [this module](https://github.com/sebajor/verilog_codes/tree/main/dsp/resize_data).
- The binary point in verilog is something that you have to deal with by yourself, for the compiler the signals are just bits. I tend to use localparams to keep track of the binary point and only use the cast modules in dsp folder to make castings.
- Make the codes in a way that they tells you when there is a error (for example rise a flag if there was an overflow).
- Parametrize all that you could parametrize.
- Think that probably you could get timing issues when compiling, deal with that before hand making the pipelining a parameter option.
- Use the generate statements to deal with different options in the parameters of the module. The idea is to re-use the available code.
- For the simulation in cocotb follow the structure of using two procedures where one writes the DUT and the other one read the outputs. This will requiere that you have already computed the golden values before launching the read procedure. 
- I had bad experience with the signed operations of cocotb, usually it reads the outputs as unsigned. When dealing with signed signals use the [these functions](https://github.com/sebajor/verilog_codes/blob/main/cocotb_python/two_comp.py), that transform the unsigned data that cocotb read to the signed one. 
- Tips about some useful and not well know features of verilog:
    - You could declare a wire/reg as signed and the compiler will make the correct operation over that signals. Keep in mind that to be completely safe all the involved signals should be signed. If you want to convert some signal you could use the functions $signed $unsigned.
    - The function $clog2 will calculate the amount of bits necesary to represent a number. 
    - The main usage of the for loops is to instantiate the same module several times. Also can be used to be lazy when assignating values.
    - Verilog dont support multi-dimensional ports this makes a little problematic when you want to parametrize a module that has a different number of parallel inputs. In those cases you can join all the signal in a large array and then iterate to get the data. Here the usage of for loops and generate statements is a must. 
    - An easy way to access to bits is using the following pattern `test_wire[10+:20]`. This accessing pattern is telling the compiler that starting from the bit 10 it should grab 20 bits (ie takes `test_wire[10:30]`). So when having a `PARALLEL` streams where each stream is of size `DATA_WIDTH` you could pack them in a big input port of size `[DATA_WIDTH*PARALLEL-1:0]` and you could access to the separated inputs with a for loop
        ```
        for(i=0; i<PARALLEL_INPUTS; i=i+1)begin
            dat = input_data[DATA_WIDTH*i+:DATA_WIDTH*(i+1)]
        end
        ```
