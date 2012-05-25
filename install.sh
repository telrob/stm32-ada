#!/bin/sh
INSTALL_PREFIX=/home/stm32/arm-gcc
mkdir download
cd download
wget -c ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-4.6.2/gcc-ada-4.6.2.tar.bz2
wget -c ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-4.6.2/gcc-core-4.6.2.tar.bz2
wget -c ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-4.6.2/gcc-g++-4.6.2.tar.bz2
wget -c ftp://sourceware.org/pub/binutils/snapshots/binutils-2.22.51.tar.bz2
wget -c ftp://ftp.gnu.org/gnu/gmp/gmp-4.3.2.tar.bz2
wget -c http://www.mpfr.org/mpfr-2.4.2/mpfr-2.4.2.tar.bz2
wget -c http://www.multiprecision.org/mpc/download/mpc-0.8.2.tar.gz
wget -c http://bugseng.com/products/ppl/download/ftp/releases/0.11.2/ppl-0.11.2.tar.bz2
wget -c ftp://gcc.gnu.org/pub/gcc/infrastructure/cloog-ppl-0.15.11.tar.gz
wget -c ftp://sources.redhat.com/pub/newlib/newlib-1.19.0.tar.gz
wget -c http://ftp.gnu.org/gnu/gdb/gdb-7.3.1.tar.bz2
cd ..
mkdir src
cd src
tar xf ../download/gcc-ada-4.6.2.tar.bz2
tar xf ../download/gcc-core-4.6.2.tar.bz2
tar xf ../download/gcc-g++-4.6.2.tar.bz2
tar xf ../download/binutils-2.22.51.tar.bz2
tar xf ../download/gmp-4.3.2.tar.bz2
tar xf ../download/mpfr-2.4.2.tar.bz2
tar xf ../download/mpc-0.8.2.tar.gz
tar xf ../download/ppl-0.11.2.tar.bz2
tar xf ../download/cloog-ppl-0.15.11.tar.gz
tar xf ../download/newlib-1.19.0.tar.gz
tar xf ../download/gdb-7.3.1.tar.bz2
cd gcc-4.6.2
patch -Np1 < ../../gcc-arm.patch
ln -sf ../gmp-4.3.2 gmp
ln -sf ../mpfr-2.4.2 mpfr
ln -sf ../mpc-0.8.2 mpc
ln -sf ../newlib-1.19.0/newlib newlib
cd ../..
mkdir -p build/binutils
mkdir -p build/gcc
mkdir -p build/gdb
cd build/binutils
(../../src/binutils-2.22.51/configure --target=arm-none-eabi --prefix=$INSTALL_PREFIX && make -j9 && make install) 2>&1 | tee make.log
cd ../gcc
(../../src/gcc-4.6.2/configure --target=arm-none-eabi --with-cpu=cortex-m4 --with-mode=thumb --prefix=$INSTALL_PREFIX --with-gnu-as --with-newlib --verbose --enable-threads --enable-languages=c,c++,ada && make -j9 && make install) 2>&1 | tee make.log
cd ../gdb
sudo apt-get install libncurses5-dev texinfo
(../../src/gdb-7.3.1/configure --target=arm-none-eabi --prefix=$INSTALL_PREFIX && make -j9 && make install) 2>&1 | tee make.log
cd ../..
PATH=$INSTALL_PREFIX/bin:$PATH ./ravenscar.sh
