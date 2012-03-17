#!/bin/sh
cd download
wget -c "http://libre2.adacore.com/ac_download/?ac_download&file=MD5%3Aab851f1cef3e9a92809333b6f289c477" -O zfp-support-2011-src.tgz
wget -c "http://libre2.adacore.com/ac_download/?ac_download&file=MD5%3Ab895640aac5c2964e7ed65f8b3cc5c35" -O gnat-gpl-2011-src.tgz
cd ../src
tar xf ../download/zfp-support-2011-src.tgz
tar xf ../download/gnat-gpl-2011-src.tgz
cd gnat-gpl-2011-src/
patch -Np1 < ../../ravenscar.patch
cd ../../ravenscar
./build-rts.sh ../src/gnat-gpl-2011-src/src/ada ../src/zfp-support-2011-src/zfp-src 2>&1 | tee ../ravenscar.log
