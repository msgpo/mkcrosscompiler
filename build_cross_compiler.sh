#!/bin/bash
ARCH=arm
ARM_OPTIONS="--with-cpu=cortex-a53 --with-fpu=neon-fp-armv8 --with-float=hard"
PPC_OPTIONS="--with-long-double-128"
GCC_OPTIONS=""
TYPE=""
if [ $ARCH = arm ]; then 
	GCC_OPTIONS=$ARM_OPTIONS
	TYPE=gnueabihf
elif [ $ARCH = powerpc ]; then
	GCC_OPTIONS=$POWERPC_OPTIONS
	TYPE=gnueabi
fi
TARGET=$ARCH-linux-$TYPE
PREFIX=$PWD/$ARCH-tools
export PATH=$PREFIX/bin:$PATH
BINUTILS_VER="2.30"
GCC_VER="7.3.0"
GDB_VER="8.1"
GLIBC_VER="2.27"
LINUX_VER="v4.16"
MPFR_VER="4.0.1"
GMP_VER="6.1.2"
MPC_VER="1.1.0"
ISL_VER="0.18"
CLOOG_VER="0.18.1"
set -e
#
# clean up
#
rm -fr build-binutils
rm -fr build-gcc
rm -fr build-gdb
rm -fr build-gdbserver
rm -fr build-glibc
rm -fr binutils-$BINUTILS_VER
rm -fr gcc-$GCC_VER
rm -fr gdb-$GDB_VER
rm -fr glibc-$GLIBC_VER
rm -fr mpfr-$MPFR_VER
rm -fr mpc-$MPC_VER
rm -fr gmp-$GMP_VER
rm -fr isl-$ISL_VER
rm -fr cloog-$CLOOG_VER
rm -fr $ARCH-tools
#
# download binutils source
#
if [ ! -f binutils-$BINUTILS_VER.tar.gz ]; then
	wget http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.gz
fi
#
#  download compiler sources
#
if [ ! -f gcc-$GCC_VER.tar.gz ]; then
	wget http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-$GCC_VER.tar.gz
fi
#
if [ ! -f mpfr-$MPFR_VER.tar.gz ]; then
	wget http://ftp.gnu.org/gnu/mpfr/mpfr-$MPFR_VER.tar.gz
fi
#
if [ ! -f gmp-$GMP_VER.tar.bz2 ]; then
	wget http://ftp.gnu.org/gnu/gmp/gmp-$GMP_VER.tar.bz2
fi
#
if [ ! -f mpc-$MPC_VER.tar.gz ]; then
	wget http://ftp.gnu.org/gnu/mpc/mpc-$MPC_VER.tar.gz
fi
#
if [ ! -f cloog-$CLOOG_VER.tar.gz ]; then
	wget https://gcc.gnu.org/pub/gcc/infrastructure/cloog-$CLOOG_VER.tar.gz
fi
#
if [ ! -f isl-$ISL_VER.tar.bz2 ]; then
	wget https://gcc.gnu.org/pub/gcc/infrastructure/isl-$ISL_VER.tar.bz2
fi
#
# download glibc source
#
if [ ! -f glibc-$GLIBC_VER.tar.gz ]; then 
	wget http://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VER.tar.gz
fi
#
# download gdb source
#
if [ ! -f gdb-$GDB_VER.tar.gz ]; then
	wget http://ftp.gnu.org/gnu/gdb/gdb-$GDB_VER.tar.gz
fi
#
# download linux kernel source
#
if [ ! -d linux/.git ]; then
	git clone https://github.com/torvalds/linux.git
fi
#
# extract
#
tar xzfv binutils-$BINUTILS_VER.tar.gz
tar xzfv gcc-$GCC_VER.tar.gz
tar xzfv mpfr-$MPFR_VER.tar.gz
tar xjfv gmp-$GMP_VER.tar.bz2
tar xzfv mpc-$MPC_VER.tar.gz
tar xzfv cloog-$CLOOG_VER.tar.gz
tar xjfv isl-$ISL_VER.tar.bz2
tar xzfv gdb-$GDB_VER.tar.gz
tar xzfv glibc-$GLIBC_VER.tar.gz
#
# build dirs
#
mkdir build-binutils
mkdir build-gcc
mkdir build-gdb
mkdir build-gdbserver
mkdir build-glibc
#
# links
#
cd gcc-$GCC_VER
ln -s ../mpfr-$MPFR_VER mpfr
ln -s ../gmp-$GMP_VER gmp
ln -s ../mpc-$MPC_VER mpc
ln -s ../cloog-$CLOOG_VER cloog
ln -s ../isl-$ISL_VER isl
cd ..
#
# binutils
#
cd build-binutils
../binutils-$BINUTILS_VER/configure \
		--prefix=$PREFIX \
		--target=$TARGET \
		--disable-multilib
make -j4
make install
cd ..
#
# kernel headers
#
cd linux
rm -fr *
git checkout -f tags/$LINUX_VER
make ARCH=$ARCH INSTALL_HDR_PATH=$PREFIX/$TARGET headers_install
cd ..
#
# GCC
#
cd build-gcc
../gcc-$GCC_VER/configure \
		--prefix=$PREFIX \
		--target=$TARGET \
		--enable-languages=c,c++ \
		--disable-multilib \
		$GCC_OPTIONS
make -j4 all-gcc
make install-gcc
cd ..
#
# glibc
#
cd build-glibc
../glibc-$GLIBC_VER/configure \
		--prefix=$PREFIX/$TARGET \
		--build=$MACHTYPE \
		--host=$TARGET \
		--target=$TARGET \
		--with-headers=$PREFIX/$TARGET/include \
		--disable-multilib \
		libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j4 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/$TARGET/lib
$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null \
		-o $PREFIX/$TARGET/lib/libc.so
touch $PREFIX/$TARGET/include/gnu/stubs.h
cd ..
#
# gcc
#
cd build-gcc
make -j4 all-target-libgcc
make install-target-libgcc
cd ..
#
# glibc
#
cd build-glibc
make -j4
make install
cd ..
#
# GCC
#
cd build-gcc
make -j4
make install
cd ..
#
# gdb
#
cd build-gdb
../gdb-$GDB_VER/configure \
		--prefix=$PREFIX \
		--target=$TARGET
make -j4
make install
cd ..
cd build-gdbserver
../gdb-$GDB_VER/gdb/gdbserver/configure \
		--prefix=$PREFIX \
		--target=$TARGET \
		--host=$TARGET
make -j4
make install
cd ..
#
# package
#
tar zcvf $ARCH-tools.tar.gz $ARCH-tools
#
# clean up
#
rm -fr build-binutils
rm -fr build-gcc
rm -fr build-gdb
rm -fr build-gdbserver
rm -fr build-glibc
rm -fr binutils-$BINUTILS_VER
rm -fr gcc-$GCC_VER
rm -fr mpfr-$MPFR_VER
rm -fr mpc-$MPC_VER
rm -fr gmp-$GMP_VER
rm -fr isl-$ISL_VER
rm -fr cloog-$CLOOG_VER
rm -fr gdb-$GDB_VER
rm -fr glibc-$GLIBC_VER