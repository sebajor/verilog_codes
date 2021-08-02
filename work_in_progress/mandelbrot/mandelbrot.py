import numpy as np
import matplotlib.pyplot as plt

def mandelbrot(iters, n, x0, y0,c=None):
    """ iters: iterations to calculate the values
        n = steps
        x0 = [x_init, x_end]
        y0 = [y_init, y_end]
        c = complex value
    """
    X = np.linspace(x0[0], x0[1],n)
    Y = np.linspace(y0[0], y0[1],n)
    [x,y] = np.meshgrid(X, 1j*Y)
    z = x+y
    if(c==None):
        c = x+y
    Q = np.zeros([n,n])

    for i in range(iters):
        index = np.abs(z)<np.inf
        Q[index] = Q[index]+1
        z = z**2+c
    return X, Y, Q


if __name__ == '__main__':
    X, Y, Q = mandelbrot(200, 512, [-2,2], [-2,2])
    plt.pcolormesh(X,Y,Q)
    plt.axis('equal')
    plt.show()



