INSTALL_PREFIX?=/opt/stm32Ada
WGET = wget -c -P download
TAR = tar -C src -xf
BUILD_MAKE = make -j9
INSTALL_MAKE = make
MKDIR = mkdir -p
PWD = `pwd`

.directories:
	$(MKDIR) src
	$(MKDIR) stamps/install
	$(MKDIR) stamps/build
	$(MKDIR) stamps/extract
	$(MKDIR) stamps/download
	$(MKDIR) stamps/configure
	$(MKDIR) stamps/patched
	$(MKDIR) build/binutils
	$(MKDIR) build/gcc
	$(MKDIR) build/gdb
	touch $@

all: stamps/install/gcc stamps/install/gdb

.downloaded: stamps/download/gcc_ada stamps/download/gcc_core stamps/download/gcc_gpp stamps/download/binutils stamps/download/gmp stamps/download/mpfr stamps/download/mpc stamps/download/ppl stamps/download/cloog stamps/download/newlib stamps/download/gdb
	touch $@

.checked: .downloaded 
	md5sum --check --strict md5sums
	touch $@

stamps/download/gcc_ada: .directories
	$(WGET) ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-4.6.2/gcc-ada-4.6.2.tar.bz2
	touch $@

stamps/download/gcc_core: .directories
	$(WGET) ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-4.6.2/gcc-core-4.6.2.tar.bz2
	touch $@

stamps/download/gcc_gpp: .directories
	$(WGET) ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-4.6.2/gcc-g++-4.6.2.tar.bz2
	touch $@

stamps/download/binutils: .directories 
	$(WGET) ftp://sourceware.org/pub/binutils/snapshots/binutils-2.22.51.tar.bz2
	touch $@

stamps/download/gmp: .directories
	$(WGET) ftp://ftp.gnu.org/gnu/gmp/gmp-4.3.2.tar.bz2
	touch $@

stamps/download/mpfr: .directories
	$(WGET) http://www.mpfr.org/mpfr-2.4.2/mpfr-2.4.2.tar.bz2
	touch $@

stamps/download/mpc: .directories
	$(WGET) http://www.multiprecision.org/mpc/download/mpc-0.8.2.tar.gz
	touch $@

stamps/download/ppl: .directories
	$(WGET) http://bugseng.com/products/ppl/download/ftp/releases/0.11.2/ppl-0.11.2.tar.bz2
	touch $@

stamps/download/cloog: .directories
	$(WGET) ftp://gcc.gnu.org/pub/gcc/infrastructure/cloog-ppl-0.15.11.tar.gz
	touch $@

stamps/download/newlib: .directories
	$(WGET) ftp://sources.redhat.com/pub/newlib/newlib-1.19.0.tar.gz
	touch $@

stamps/download/gdb: .directories
	$(WGET) http://ftp.gnu.org/gnu/gdb/gdb-7.3.1.tar.bz2
	touch $@

# Extraction

stamps/extract/gcc: stamps/extract/gcc_ada stamps/extract/gcc_core stamps/extract/gcc_gpp
	touch $@

stamps/extract/gcc_ada: .checked src
	$(TAR) download/gcc-ada-4.6.2.tar.bz2
	touch $@

stamps/extract/gcc_core: .checked src
	$(TAR) download/gcc-core-4.6.2.tar.bz2
	touch $@

stamps/extract/gcc_gpp: .checked src
	$(TAR) download/gcc-g++-4.6.2.tar.bz2
	touch $@

stamps/extract/binutils: .checked src 
	$(TAR) download/binutils-2.22.51.tar.bz2
	touch $@

stamps/extract/gmp: .checked src
	$(TAR) download/gmp-4.3.2.tar.bz2
	touch $@

stamps/extract/mpfr: .checked src
	$(TAR) download/mpfr-2.4.2.tar.bz2
	touch $@

stamps/extract/mpc: .checked src
	$(TAR) download/mpc-0.8.2.tar.gz
	touch $@

stamps/extract/ppl: .checked src
	$(TAR) download/ppl-0.11.2.tar.bz2
	touch $@

stamps/extract/cloog: .checked src
	$(TAR) download/cloog-ppl-0.15.11.tar.gz
	touch $@

stamps/extract/newlib: .checked src
	$(TAR) download/newlib-1.19.0.tar.gz
	touch $@

stamps/extract/gdb: .checked src
	$(TAR) download/gdb-7.3.1.tar.bz2
	touch $@

stamps/install/binutils: stamps/build/binutils
	$(INSTALL_MAKE) -C build/binutils install
	touch $@

stamps/build/binutils: stamps/configure/binutils
	$(BUILD_MAKE) -C build/binutils
	touch $@

stamps/configure/binutils: build/binutils stamps/extract/binutils
	cd build/binutils && ../../src/binutils-2.22.51/configure --target=arm-none-eabi --prefix=$(INSTALL_PREFIX) 
	touch $@

	
stamps/patched/gcc: stamps/extract/gcc stamps/extract/gmp stamps/extract/mpfr stamps/extract/mpc stamps/extract/newlib 
	patch --directory=src/gcc-4.6.2 -Np1 < gcc-arm.patch
	ln -sf $(PWD)/src/gmp-4.3.2 src/gcc-4.6.2/gmp
	ln -sf $(PWD)/src/mpfr-2.4.2 src/gcc-4.6.2/mpfr
	ln -sf $(PWD)/src/mpc-0.8.2 src/gcc-4.6.2/mpc
	ln -sf $(PWD)/src/newlib-1.19.0/newlib src/gcc-4.6.2/newlib
	touch $@

# We face lots of issues building the GCC and GDB docs. We instruct GCC not to
# build the doc... but it just does not want to listen. Hence this ugly hack, 
# in which we pretend the makeinfo command is a non-existent file. Configure
# checks for its existence (not its functionality...), bails and accepts not to
# build the info.
stamps/configure/gcc: stamps/patched/gcc stamps/install/binutils build/gcc
	cd build/gcc && MAKEINFO=/usr/blahblahblah ../../src/gcc-4.6.2/configure --target=arm-none-eabi --with-cpu=cortex-m4 --with-mode=thumb --prefix=$(INSTALL_PREFIX) --with-gnu-as --with-newlib --verbose --enable-threads --enable-languages=c,c++,ada
	touch $@

stamps/build/gcc: stamps/configure/gcc
	$(BUILD_MAKE) -C build/gcc
	touch $@

stamps/install/gcc: stamps/build/gcc
	$(INSTALL_MAKE) -C build/gcc install
	touch $@


#sudo apt-get install liddbncurses5-dev texinfo
stamps/configure/gdb: stamps/extract/gdb stamps/install/gcc build/gdb
	cd build/gdb && MAKEINFO=/usr/blahblahblah ../../src/gdb-7.3.1/configure --target=arm-none-eabi --prefix=$(INSTALL_PREFIX)
	touch $@

stamps/build/gdb: stamps/configure/gdb
	$(BUILD_MAKE) -C build/gdb
	touch $@

stamps/install/gdb: stamps/build/gdb
	$(INSTALL_MAKE) -C build/gdb install


#PATH=$INSTALL_PREFIX/bin:$PATH ./ravenscar.sh
