#!/bin/sh
  
# example
# ./build.sh https://github.com/NavCoin/navcoin-core.git master ALL

# $DIR is the absolute path of where you cloned gitian-builder

DIR=/home/navworker

VERSION=$2
URL=$1
OS=$3

if [ "$1" = "" ]; then
        echo "Usage $0 {repository} {branch|tag|commit} {LINUX|OSX|WIN|ALL}"
        exit 1
fi

if [ "$2" = "" ]; then
        echo "Usage $0 $1 {branch|tag|commit} {LINUX|OSX|WIN|ALL}"
        exit 1
fi

case "$OS" in
        LINUX)
                echo "Building for x86, aarch, i686 and arm Linux"
                ;;
        OSX)
                echo "Building for Mac OSX"
                ;;
        WIN)
                echo "Building for 32bit and 64bit Windows"
                ;;
        ALL)
                echo "Building for all compatible systems"
                ;;
        *)
                echo "Usage $0 $1 $2 $3 {LINUX|OSX|WIN|ALL}"
                exit 1
esac

rm  -rf $DIR/navcoin-core && cd $DIR && git clone $URL

cd $DIR/navcoin-core ; git pull ; git checkout $VERSION ; git pull

mkdir -p $DIR/binaries/$VERSION

if [ "$OS" = "LINUX" ] || [ "$OS" = "ALL" ] ; then
        echo "$OS $VERSION $URL"
        cd $DIR/gitian-builder && USE_DOCKER=1 ./bin/gbuild -j 6 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} $DIR/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
        mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz $DIR/binaries/$VERSION/
        cd $DIR/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
fi

if [ "$OS" = "OSX" ] || [ "$OS" = "ALL" ] ; then
        if [ "$OS" = "OSX" ] ; then
                cd $DIR/gitian-builder && USE_DOCKER=1 ./bin/gbuild -j 6 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} $DIR/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
        fi
        cd $DIR/gitian-builder && USE_DOCKER=1 ./bin/gbuild -j 6 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} $DIR/navcoin-core/contrib/gitian-descriptors/gitian-osx.yml
        mv build/out/navcoin-*-osx.tar.gz inputs/navcoin-osx.tar.gz
        mv build/out/navcoin-*.tar.gz build/out/navcoin-*.dmg $DIR/binaries/$VERSION/
        cd $DIR/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
fi

if [ "$OS" = "WIN" ] || [ "$OS" = "ALL" ] ; then
        if [ "$OS" = "WIN" ] ; then
                cd $DIR/gitian-builder && USE_DOCKER=1 ./bin/gbuild -j 6 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} $DIR/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
        fi
        cd $DIR/gitian-builder && USE_DOCKER=1 ./bin/gbuild -j 6 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} $DIR/navcoin-core/contrib/gitian-descriptors/gitian-win.yml
        mv build/out/navcoin-*-win.tar.gz inputs/navcoin-win.tar.gz
        mv build/out/navcoin-*.zip build/out/navcoin-*.exe $DIR/binaries/$VERSION/
fi

cd $DIR/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
rm $DIR/binaries/$VERSION/*debug*
cd $DIR/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
