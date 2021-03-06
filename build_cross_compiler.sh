#!/bin/bash
# 
# prerequisites for ubuntu: sudo apt-get build-dep binutils gcc gdb glibc linux-image-$(uname -r) 
#
ARCHS="arm64 armhf arm powerpc"
# Raspberry PI 2 -mcpu=cortex-a7 -mfpu=neon-vfpv4
# Raspberry PI 2 ver 1.2 and Raspberry PI 3 -mcpu=cortex-a53 -mfpu=neon-fp-armv8
ARM_OPTIONS_HF="--with-cpu=cortex-a7 --with-fpu=neon-fp-armv8 --with-float=hard"
ARM64_OPTIONS="--with-cpu=cortex-a53"
ARM_OPTIONS="--with-cpu=cortex-a7 --with-fpu=neon-vfpv4"
PPC_OPTIONS="--with-long-double-128"
GCC_OPTIONS=""
TYPE=""
for ARCH in $ARCHS; do
if [ $ARCH = armhf ]; then
	TARGET_DIR=$ARCH-target
	GCC_OPTIONS=$ARM_OPTIONS_HF
	TYPE=gnueabihf
	ARCH=arm
	LINUX_ARCH=arm
elif [ $ARCH = arm ]; then
	TARGET_DIR=$ARCH-target
	GCC_OPTIONS=$ARM_OPTIONS
	TYPE=gnueabi
	ARCH=arm
	LINUX_ARCH=arm
elif [ $ARCH = arm64 ]; then
	TARGET_DIR=$ARCH-target
	GCC_OPTIONS=$ARM64_OPTIONS
	TYPE=gnueabi
	ARCH=aarch64
	LINUX_ARCH=arm64
elif [ $ARCH = powerpc ]; then
	TARGET_DIR=$ARCH-target
	GCC_OPTIONS=$POWERPC_OPTIONS
	TYPE=gnueabi
	ARCH=powerpc
	LINUX_ARCH=powerpc
fi
TARGET=$ARCH-linux-$TYPE
PREFIX=$PWD/cross
export PATH=$PREFIX/bin:$PATH
BINUTILS_VER="2.32"
GCC_VER="8.3.0"
GDB_VER="8.2"
GLIBC_VER="2.29"
LINUX_VER="5.0"
MPFR_VER="4.0.1"
GMP_VER="6.1.2"
MPC_VER="1.1.0"
ISL_VER="0.18"
CLOOG_VER="0.18.1"
CPUS=$(nproc --all)
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
if [ ! -d cross ]; then
	mkdir cross
fi
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
cd binutils-$BINUTILS_VER
ln -s ../mpfr-$MPFR_VER mpfr
ln -s ../gmp-$GMP_VER gmp
ln -s ../mpc-$MPC_VER mpc
ln -s ../cloog-$CLOOG_VER cloog
ln -s ../isl-$ISL_VER isl
cd ..
cd gdb-$GDB_VER
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
		--disable-multilib \
		--disable-nls
make -j$CPUS
make -j$CPUS install
cd ..
#
# kernel headers
#
cd linux
rm -fr *
git checkout -f tags/v$LINUX_VER
make -j$CPUS ARCH=$LINUX_ARCH INSTALL_HDR_PATH=$PREFIX/$TARGET headers_install
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
		--disable-nls \
		$GCC_OPTIONS
make -j$CPUS all-gcc
make -j$CPUS install-gcc
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
		--enable-kernel=$LINUX_VER \
		--disable-nls \
		libc_cv_forced_unwind=yes
make -j$CPUS install-bootstrap-headers=yes install-headers
make -j$CPUS csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/$TARGET/lib
$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null \
		-o $PREFIX/$TARGET/lib/libc.so
touch $PREFIX/$TARGET/include/gnu/stubs.h
cd ..
#
# gcc
#
cd build-gcc
make -j$CPUS all-target-libgcc
make -j$CPUS install-target-libgcc
cd ..
#
# glibc
#
cd build-glibc
make -j$CPUS
make -j$CPUS install
cd ..
#
# GCC
#
cd build-gcc
make -j$CPUS
make -j$CPUS install
cd ..
# gdb
#
cd build-gdb
../gdb-$GDB_VER/configure \
		--prefix=$PREFIX \
		--target=$TARGET \
		--disable-nls
make -j$CPUS
make -j$CPUS install
cd ..
#
# glibc for target
#
rm -fr build-glibc
mkdir build-glibc
cd build-glibc
../glibc-$GLIBC_VER/configure \
		--prefix= \
		--build=$MACHTYPE \
		--host=$TARGET \
		--target=$TARGET \
		--disable-multilib \
		--enable-kernel=$LINUX_VER \
		--disable-nls
make -j$CPUS
make -j$CPUS DESTDIR=$PREFIX/$TARGET_DIR install
cd ..
#
# libgcc, libstdc++ for target
#
rm -fr build-gcc
mkdir build-gcc
cd build-gcc
../gcc-$GCC_VER/configure \
		--prefix= \
		--build=$MACHTYPE \
		--target=$TARGET \
		--host=$TARGET \
		--enable-languages=c,c++ \
		--disable-multilib \
		--disable-nls \
		$GCC_OPTIONS
make -j$CPUS all-target-libgcc
make -j$CPUS all-target-libstdc++-v3
make -j$CPUS DESTDIR=$PREFIX/$TARGET_DIR install-target-libgcc
make -j$CPUS DESTDIR=$PREFIX/$TARGET_DIR install-target-libstdc++-v3
cd ..
#
cd build-gdbserver
../gdb-$GDB_VER/gdb/gdbserver/configure \
		--prefix= \
		--build=$MACHTYPE \
		--target=$TARGET \
		--host=$TARGET \
		--disable-nls
make -j$CPUS
make -j$CPUS DESTDIR=$PREFIX/$TARGET_DIR install
cd ..
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
done
#
# gzip
#
tar zcvf cross.tar.gz cross
exit
