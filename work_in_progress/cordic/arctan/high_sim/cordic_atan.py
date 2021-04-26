import numpy as np
import ipdb

def cordic_atan(y,x, iters=16):
    """x,y in (-1,1)
    """
    #reduction to the first quadrant
    #ipdb.set_trace()
    flag1 =0;
    if(y<0 and x>0):
        #-arctan
        flag1 = 1
    if(y>0 and x<0):
        ##pi-arctan
        flag1 = 2
    if(y<0 and x<0):
        #-pi+arctan
        flag1 = 3
    x_i = np.abs(x); y_i = np.abs(y)
    flag2 = 0
    if(x_i<y_i):
        #the output is now pi/2-arctan(y,x)
        flag2 = 1
        aux = x_i
        x_i = y_i; y_i = aux;
    #cordic
    d_i = -1; z_i=0 
    y_new = 0; 
    for i in range(iters):
        #ipdb.set_trace()
        #print(y_new)
        x_new = x_i-y_i*d_i*2.**(-i)
        y_new = y_i+x_i*d_i*2.**(-i)
        z_new = z_i-d_i*np.arctan(2**(-i))
        if(y_new==0):
            break
        if(y_new>0):
            d_i = -1
        else:
            d_i = 1
        x_i = x_new; y_i = y_new; z_i = z_new
    if(flag2):
        out = np.pi/2-z_i
    else:
        out = z_i 
    if(flag1==1):
        out = -out#out = -z_i
    elif(flag1==2):
        out = np.pi-out#out = np.pi-z_i
    elif(flag1==3):
        out = out-np.pi#out = z_i-np.pi
    else:
        out = out

    #if(flag2==1):
    #    out = np.pi/2-out
    return [x_i, y_i, z_i, out]


def cordic_bin_atan(y,x, iters=16):
    """x,y in (-1,1)
    """
    #reduction to the first quadrant
    #ipdb.set_trace()
    flag1 =0;
    if(y<0 and x>0):
        #-arctan
        flag1 = 1
    if(y>0 and x<0):
        ##pi-arctan
        flag1 = 2
    if(y<0 and x<0):
        #-pi+arctan
        flag1 = 3
    x_i = np.abs(x); y_i = np.abs(y)
    flag2 = 0
    if(x_i<y_i):
        #the output is now pi/2-arctan(y,x)
        flag2 = 1
        aux = x_i
        x_i = y_i; y_i = aux;
    #cordic
    d_i = -1; z_i=0 
    y_new = 0; 
    for i in range(iters):
        #ipdb.set_trace()
        #print(y_new)
        x_new = x_i-y_i*d_i*2.**(-i)
        y_new = y_i+x_i*d_i*2.**(-i)
        z_new = z_i-d_i*np.arctan(2**(-i))*1./np.pi
        if(y_new==0):
            break
        if(y_new>0):
            d_i = -1
        else:
            d_i = 1
        x_i = x_new; y_i = y_new; z_i = z_new
    if(flag2):
        out = 1./2-z_i
    else:
        out = z_i 
    if(flag1==1):
        out = -out#out = -z_i
    elif(flag1==2):
        out = 1-out#out = np.pi-z_i
    elif(flag1==3):
        out = out-1#out = z_i-np.pi
    else:
        out = out

    #if(flag2==1):
    #    out = np.pi/2-out
    return [x_i, y_i, z_i, out]

def cordic_bin_quant_atan(y,x, iters=16):
    """x,y in (-1,1)
    """
    #reduction to the first quadrant
    #ipdb.set_trace()
    flag1 =0;
    if(y<0 and x>0):
        #-arctan
        flag1 = 1
    if(y>0 and x<0):
        ##pi-arctan
        flag1 = 2
    if(y<0 and x<0):
        #-pi+arctan
        flag1 = 3
    x_i = np.abs(x); y_i = np.abs(y)
    flag2 = 0
    if(x_i<y_i):
        #the output is now pi/2-arctan(y,x)
        flag2 = 1
        aux = x_i
        x_i = y_i; y_i = aux;
    #cordic
    d_i = -1; z_i=0 
    y_new = 0; 
    for i in range(iters):
        #ipdb.set_trace()
        #print(y_new)
        x_new = x_i-y_i*d_i*2.**(-i)
        y_new = y_i+x_i*d_i*2.**(-i)
        z_new = z_i-d_i*(int(np.arctan(2**(-i))*1./np.pi*2**15)/2.**15)
        if(y_new==0):
            break
        if(y_new>0):
            d_i = -1
        else:
            d_i = 1
        x_i = x_new; y_i = y_new; z_i = z_new
    if(flag2):
        out = 1./2-z_i
    else:
        out = z_i 
    if(flag1==1):
        out = -out#out = -z_i
    elif(flag1==2):
        out = 1-out#out = np.pi-z_i
    elif(flag1==3):
        out = out-1#out = z_i-np.pi
    else:
        out = out

    #if(flag2==1):
    #    out = np.pi/2-out
    return [x_i, y_i, z_i, out]
