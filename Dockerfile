FROM sglanger/centos-cuda

MAINTAINER Steve Langer <sglanger@bluebottle.COM>


# Ensure the CUDA libs and binaries are in the correct environment variables
ENV LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-7.0/lib64
ENV PATH=$PATH:/usr/local/cuda-7.0/bin
CMD ["/bin/bash"]

# note that chainer uses blas. openblas can use multiple CPUs but numpy must be recompiled to use these...

RUN yum -y install git python-devel
RUN yum -y install gcc-gfortran libmpc-devel
RUN yum -y install wget

# can do this, but it will not be optimized for machine...
#RUN yum -y install libopenblas-devel liblapack-devel

# this is probably better...
RUN mkdir ~/src && cd ~/src && \
  git clone https://github.com/xianyi/OpenBLAS && \
  cd ~/src/OpenBLAS && \
  make FC=gfortran && \
  make PREFIX=/opt/OpenBLAS install

# now update the library system:
RUN echo /opt/OpenBLAS/lib >  /etc/ld.so.conf.d/openblas.conf
RUN ldconfig
ENV LD_LIBRARY_PATH=/opt/OpenBLAS/lib:$LD_LIBRARY_PATH

# now install numpy source
# this does dev version, not stable and chainer uninstalls it...
# RUN cd ~/src && \
#  git clone https://github.com/numpy/numpy

RUN yum -y install Cython

ADD numpy.tar.gz /root/src

RUN echo [default]  >                           ~/src/numpy/site.cfg && \
  echo include_dirs = /opt/OpenBLAS/include >>  ~/src/numpy/site.cfg && \
  echo library_dirs = /opt/OpenBLAS/lib >>      ~/src/numpy/site.cfg && \
  echo [openblas] >>                            ~/src/numpy/site.cfg && \
  echo openblas_libs = openblas >>              ~/src/numpy/site.cfg && \
  echo library_dirs = /opt/OpenBLAS/lib >>      ~/src/numpy/site.cfg && \
  echo [lapack]  >>                             ~/src/numpy/site.cfg && \
  echo lapack_libs = openblas >>                ~/src/numpy/site.cfg && \
  echo library_dirs = /opt/OpenBLAS/lib >>      ~/src/numpy/site.cfg


RUN cd ~/src/numpy && \
  python setup.py config && \
  python setup.py build --fcompiler=gnu95 && \
  python setup.py install

RUN yum install -y epel-release
RUN yum install -y python-pip

# install pycuda stuff
RUN yum install gcc-c++

RUN pip install --upgrade pip
RUN pip install mako
RUN pip install pycuda

# copy a little file over to allow testing of GPU access
ADD deviceQuery /usr/local/cuda/bin/
RUN cd /usr/local/cuda/bin &&  \
  chmod +x deviceQuery

ADD pybench.py ~
RUN time python pybench.py
ENV OPENBLAS_NUM_THREADS=6

RUN time python pybench.py 6



