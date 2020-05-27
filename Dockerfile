#### Gromacs 2019.4 patched with Plumed 2.6, CUDA-enabled  ####

# NB: Targetting local CPU microarchitecture with at least Broadwell/ AV2_256 support (-march=broadwell)
#     -> If "SIGILL" or "Illegal instruction", rebuild with appropriate flags

FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu16.04

LABEL maintainer="Eliane Briand <eliane@br.iand.fr>"

# disable apt-get questions
ARG DEBIAN_FRONTEND=noninteractive

# build dir
RUN mkdir build_dir_tmp
ARG work=/build_dir_tmp
WORKDIR $work


# apt-get dependencies variables
ARG fftw_buildDeps="wget cmake build-essential gfortran"
ARG plumed_buildDeps="git"
ARG plumed_runtimeDeps="gawk libopenblas-base libgomp1 make openssh-client libboost-all-dev openmpi-bin vim zlib1g git g++ libopenblas-dev libopenmpi-dev libmatheval-dev zlib1g-dev "
#ARG cuda_buildDeps="cuda-compiler-10-0"
ARG gromacs_buildDeps="cmake"
ARG gromacs_runtimeDeps="libfftw3-dev hwloc python"
ARG plumed_retry_deps="python3-setuptools  python3-pip"


# install dependencies 
RUN apt-get -yq update \
 && apt-get -yq install --no-install-recommends $plumed_buildDeps $gromacs_buildDeps $plumed_runtimeDeps $fftw_buildDeps $gromacs_runtimeDeps $plumed_retry_deps \
 && apt-get clean
 
# Build & install fftw
WORKDIR $work
RUN wget -nv http://www.fftw.org/fftw-3.3.8.tar.gz \
    && tar xf fftw-3.3.8.tar.gz && cd ./fftw-3.3.8 \
    && ./configure --prefix="/usr/local/"  --enable-sse --enable-sse2 --enable-avx --enable-avx2  --enable-avx-128-fma  --enable-single CFLAGS=" -fPIC -O3 -march=broadwell " \
    && make -j "$(nproc)" \
    && make install \
    && rm -rf ../fftw-3.3.8
 
 
WORKDIR $work

# Build & install plumed
RUN wget -nv https://github.com/plumed/plumed2/releases/download/v2.6.0/plumed-2.6.0.tgz \
    && tar xf plumed-2.6.0.tgz && cd ./plumed-2.6.0 \
    && ./configure --prefix="/usr/local" --enable-asmjit --enable-mpi --enable-zlib --enable-boost_graph --enable-boost_serialization --enable-fftw CXXFLAGS="  -fPIC -O3 -march=broadwell " LDFLAGS="-L/usr/local/lib -lopenblas " CPPFLAGS="-I/usr/local/include " --disable-static-archive \
    && make -j "$(nproc)" \
    && make install \
    && rm -rf ../plumed2

# set plumed env vars
ENV PATH="/usr/local/bin/:${PATH}"

ENV PLUMED_KERNEL="/usr/local/lib/libplumedKernel.so"

ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"


# Fetch gromacs
WORKDIR $work
RUN wget -nv http://ftp.gromacs.org/pub/gromacs/gromacs-2019.4.tar.gz \
    && tar xf gromacs-2019.4.tar.gz

# Patch gromacs with plumed, build and install
WORKDIR $work/gromacs-2019.4
RUN plumed patch -p --runtime -e "gromacs-2019.4" \
 && mkdir -p build
WORKDIR $work/gromacs-2019.4/build
RUN cmake .. -DCMAKE_INSTALL_PREFIX="/usr/local/" -DGMX_SIMD="AVX2_256" -DGMX_BUILD_OWN_FFTW="off" -DGMX_GPU="on" -DGMX_USE_NVML="off" \
 && make -j "$(nproc)" \
 && make install \
 && rm -rf ../../gromacs-2019.4

#MPI cmake (if needed): -DGMX_MPI=on -DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx

RUN pip3 install pyyaml

WORKDIR /

# source gromacs env vars
RUN /bin/bash -c "source /usr/local/bin/GMXRC.bash"

# print gromacs and plumed versions
RUN gmx --version \
  && echo "Plumed version: $(plumed info --long-version)" 
