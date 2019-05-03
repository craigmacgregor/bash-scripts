#!/bin/sh

# example
# ./build.sh https://github.com/NAVCoin/navcoin-core.git master

export VERSION=$2
export URL=$1
export USE_LXC=1
export GITIAN_HOST_IP=10.0.3.2
export LXC_GUEST_IP=10.0.3.5
 
rm -rf /home/debian/navcoin-core && cd /home/debian && git clone $URL
 
cd /home/debian/navcoin-core && git pull ; git checkout $VERSION ; git pull
 
mkdir -p /home/debian/binaries/$VERSION

cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-osx.yml
mv build/out/navcoin-*-osx.tar.gz inputs/navcoin-osx.tar.gz
mv build/out/navcoin-*.tar.gz build/out/navcoin-*.dmg /home/debian/binaries/$VERSION/
cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc

cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-linux.yml
mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz /home/debian/binaries/$VERSION/
cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc

cd /home/debian/gitian-builder && ./bin/gbuild --memory 7000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-win.yml
mv build/out/navcoin-*-win.tar.gz inputs/navcoin-win.tar.gz
mv build/out/navcoin-*.zip build/out/navcoin-*.exe /home/debian/binaries/$VERSION/
 
cd /home/debian/gitian-builder && ./bin/gbuild --memory 3000 -j 2 --commit navcoin-core=${VERSION} --url navcoin-core=${URL} /home/debian/navcoin-core/contrib/gitian-descriptors/gitian-arm.yml
mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz /home/debian/binaries/$VERSION/
cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
 
cd /home/debian/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
 
#rm /home/blanka/binaries/$VERSION/*debug*
#cd /home/blanka/binaries/$VERSION && rm *SHA256SUM* ; sha256sum * > $VERSION.SHA256SUM.asc
