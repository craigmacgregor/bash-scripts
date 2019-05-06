#!/bin/sh

# example
# ./build.sh https://github.com/NavCoin/navcoin-core.git master {X86|OSX|WIN|ARM|ALL}

export VERSION=$2
export URL=$1
export USE_LXC=1
export GITIAN_HOST_IP=10.0.3.2
export LXC_GUEST_IP=10.0.3.5

OS=$3

if [ "$1" = "" ]; then
	echo "Usage $0 {repository} {branch|tag|commit} {X86|OSX|WIN|ARM|ALL}"
	exit 1
fi

if [ "$2" = "" ]; then
	echo "Usage $0 $1 {branch|tag|commit} {X86|OSX|WIN|ARM|ALL}"
	exit 1
fi

case "$OS" in
	X86)
		echo "Building for x86 and Aarch Linux"
		;;
	OSX)
		echo "Building for Mac OSX"
		;;
	WIN)
		echo "Building for 32bit and 64bit Windows"
		;;
	ARM)
		echo "Building for Arm and i686 Linux"
		;;
	ALL)
		echo "Building for all compatible systems"
		;;
	*)
		echo "Usage $0 $1 $2 $3 {X86|OSX|WIN|ARM|ALL}"
		exit 1
esac

rm  -rf /home/debian/navcoin-core && cd /home/debian && git clone $URL
 
cd /home/debian/navcoin-core && git pull ; git checkout $VERSION ; git pull
 
mkdir -p /home/debian/binaries/$VERSION

if [ "$OS" = "X86" ] || [ "$OS" = "ALL" ] ; then
	cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
	mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz /home/debian/binaries/$VERSION/
	cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
fi

if [ "$OS" = "OSX" ] || [ "$OS" = "ALL" ] ; then
	cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
	cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-osx.yml
	mv build/out/navcoin-*-osx.tar.gz inputs/navcoin-osx.tar.gz
	mv build/out/navcoin-*.tar.gz build/out/navcoin-*.dmg /home/debian/binaries/$VERSION/
	cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
fi

if [ "$OS" = "WIN" ] || [ "$OS" = "ALL" ] ; then
	cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
	cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-win.yml
	mv build/out/navcoin-*-win.tar.gz inputs/navcoin-win.tar.gz
	mv build/out/navcoin-*.zip build/out/navcoin-*.exe /home/debian/binaries/$VERSION/
fi

if [ "$OS" = "ARM" ] || [ "$OS" = "ALL" ] ; then
	cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
	cd /home/debian/gitian-builder && ./bin/gbuild --memory 3000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-arm.yml
	mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz /home/debian/binaries/$VERSION/
	cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
fi

cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
 
#rm /home/blanka/binaries/$VERSION/*debug*
#cd /home/blanka/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
