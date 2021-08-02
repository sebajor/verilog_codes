This module generate mandelbrot images ina given set.
To paralelize the calculation we set the calculation of differents lines of the
images to different instances.
The number of computation instances is parametrizable, the only requirement 
is that the the height should be divisible by that number.

TODO:
There is a problem in the synchonization of the mandelbrot_line!!
