#!/bin/bash

# Script to build the ravenscar run-time for STM32.
# Access to GNAT and ZFP-support sources are required.

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 gnat-src zfp-src"
  exit 1
fi

gnatsrc=$1
zfpsrc=$2

# You can use ln for debugging.
#CP="ln -s"
CP=cp

GNATMAKE=`which arm-none-eabi-gnatmake || true`

if [ ! -x "$GNATMAKE" ]; then
  echo "Missing arm-none-eabi-gnatmake"
  exit 1
fi

target_objdir=`dirname $GNATMAKE`/../lib/gcc/arm-none-eabi/4.6.2/rts-raven

objdir=`mktemp -d`

echo "Building RTS in '$objdir'"

if [ -d $target_objdir ]; then
  echo "Object dir $target_objdir already exists"
  exit 1
fi

# Create directories.
mkdir $objdir/adainclude
mkdir $objdir/adalib

# Build list of sources.
make -f $gnatsrc/Makefile.hie RTS=ravenscar-sfp TARGET=none-elf \
 GNAT_SRC_DIR=$gnatsrc show-sources |grep -v "^make"  > ravenscar.src

sed -i "s/s-bbtiev.ad[sb]//g" ./ravenscar.src
sed -i "s/a-rttiev.ad[sb]//g" ./ravenscar.src
sed -i "s/s-bbseou.ad[sb]//g" ./ravenscar.src
sed -i "s/s-sssita.ad[sb]//g" ./ravenscar.src

# Get them.
. ./ravenscar.src

rm -f ravenscar.src

extra_target_pairs="s-multip.adb:s-multip-raven-default.adb"

sedcmd=""
for i in $TARGET_PAIRS $extra_target_pairs; do
  sedcmd="$sedcmd -e s:$i:"
done

# Copy sources.
for f in $LIBGNAT_SOURCES $LIBGNARL_SOURCES $LIBGNAT_NON_COMPILABLE_SOURCES s-bbpere.ads; do
  if [ -f $f ]; then
      # Locally overriden source file.
      $CP $PWD/$f $objdir/adainclude/$f
  else
      # Get from GNAT.
      tf=`echo $f | sed $sedcmd`
      if [ "$f" = "s-secsta.ads" ]; then
          sed -e "/Default_Secondary_Stack_Size : /s/ := .*;/ := 512;/" \
              < $gnatsrc/$tf > $objdir/adainclude/$f
      else
          $CP $gnatsrc/$tf $objdir/adainclude/$f
      fi
  fi
done

# Copy some zfp sources
for f in memory_{set,copy,compare}.{ads,adb}; do
   $CP $zfpsrc/$f $objdir/adainclude/$f
done

builddir=`mktemp -d`
echo -e "RAVENSCAR_SRC=`pwd`\nRTS_BASE=$objdir\ninclude \$(RAVENSCAR_SRC)/Makefile.rts.inc" >> $builddir/Makefile
make -C $builddir
cp $builddir/libgnat.a $objdir/adalib/libgnat.a
cp $builddir/libstm32.a $objdir/adalib/libstm32.a
cp $builddir/*.ali $objdir/adalib
#rm -rf $builddir
arm-none-eabi-ar rc $objdir/adalib/libgnarl.a

mv $objdir $target_objdir

exit 0
