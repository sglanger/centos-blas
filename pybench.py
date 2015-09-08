import numpy
from numpy.random import random

def test():

    i = 1000
    data = random((i,i))
    result = numpy.linalg.eig(data)

if __name__ == '__main__':
    test()
