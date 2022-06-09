# Automatic Gain Control


A basic diagram is 

input --------------------------------------------------> X ----> out 
  |                                                       |
   ----> power ----> mov avg --> ref comparison--> adjust coef

This AGC works minimizing the error beetween the input power and a power
reference. It is based in just a least square method so it could have problems with
the convergence.


