#!/bin/bash
set -e
 
if which podman &> /dev/null; then
  container=podman
elif which docker &> /dev/null; then
  container=docker
else
  echo "Podman or docker have to be in \$PATH"
  exit 1
fi

function build_linux_sdk() {

  cp config-badgeros64 .config
  toolchain_prefix=riscv64-badgeros-linux-gnu

  ${container} build -f Dockerfile.linux-builder -t badgeros-buildroot-builder-linux
  ${container} run -it --rm -v $(pwd):/tmp/buildroot:z -w /tmp/buildroot -e FORCE_UNSAFE_CONFIGURE=1 --userns=keep-id badgeros-buildroot-builder-linux bash -c "make clean; make syncconfig; make sdk"

  mkdir -p badgeros-toolchains
  tar xf output/images/${toolchain_prefix}_sdk-buildroot.tar.gz -C badgeros-toolchains

  pushd badgeros-toolchains/${toolchain_prefix}_sdk-buildroot/bin
  for f in $(ls -1 riscv64-linux-*); do ln -s ${f} $(echo $f | sed -e 's/linux/badgeros/'); done
  popd

  pushd badgeros-toolchains
  tar -cjf ${toolchain_prefix}_sdk-buildroot.tar.bz2 ${toolchain_prefix}_sdk-buildroot
  rm -rf ${toolchain_prefix}_sdk-buildroot
  popd
}

build_linux_sdk

echo
echo "***************************************"
echo "Build succesful your toolchain is in badgeros-toolchains/${toolchain_prefix}_sdk-buildroot.tar.gz"
