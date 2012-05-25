#!/bin/sh
cd download
wget -c "http://mirrors.cdn.adacore.com/art/fea42ac613f142431a304a950ec9da0dc3a9318d" -O zfp-support-2011-src.tgz
wget -c "http://mirrors.cdn.adacore.com/art/d5bfc6f4b0284b14d961097f37f666b5e6b9100e" -O gnat-gpl-2011-src.tgz
cd ../src
tar xf ../download/zfp-support-2011-src.tgz
tar xf ../download/gnat-gpl-2011-src.tgz
cd gnat-gpl-2011-src/
patch -Np1 < ../../ravenscar.patch
cd ../../ravenscar
./build-rts.sh ../src/gnat-gpl-2011-src/src/ada ../src/zfp-support-2011-src/zfp-src 2>&1 | tee ../ravenscar.log
