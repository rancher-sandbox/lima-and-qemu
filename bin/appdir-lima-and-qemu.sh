#!/bin/bash

# This is a helper script to build an appDir structure to
# include lima and qemu as part of an AppImage binary.
# The binaries build should happen in the oldest available Ubuntu LTS

function error {
  >&2 echo "$@"
  exit 1
}

function keepListedFiles {
  local dir=$1
  local list=$2

  [ -d "${dir}" ] || error "${dir} is not a directory"
  
  for it in $(ls ${dir}); do
    if [[ "${list}" =~ \ ${it}\  ]]; then
      continue
    fi
    [ -n "${it}" ] && rm -rf "${dir}/${it}"
  done
}

set -e

[ -n "${1}" ] || error "One argument to the built app dir is required"
[ -d "${1}" ] || error "Directory ${1} doesn't exist"

appDir=$1
dist="lima-and-qemu"

# Inspired on linuxdeployqt https://github.com/probonopd/linuxdeployqt/blob/master/tools/linuxdeployqt/excludelist.h
# Linuxdeployqt is a tool created by probonopd, the AppImage creator
excludeLibs=" libz.so.1 "
excludeLibs+="libgio-2.0.so.0 "
excludeLibs+="libgobject-2.0.so.0 "
excludeLibs+="libglib-2.0.so.0 "
excludeLibs+="libutil.so.1 "
excludeLibs+="libm.so.6 "
excludeLibs+="libgcc_s.so.1 "
excludeLibs+="libpthread.so.0 "
excludeLibs+="libc.so.6 "
excludeLibs+="libresolv.so.2 "
excludeLibs+="libdl.so.2 "
excludeLibs+="librt.so.1 "
excludeLibs+="libuuid.so.1 "

firmwareOfInterest=" bios-256k.bin edk2-x86_64-code.fd efi-virtio.rom kvmvapic.bin vgabios-virtio.bin "
executablesOfInterest=" qemu-system-x86_64 qemu-img limactl "

mkdir -p "${appDir}/lib"

linkedLibs=$(ldd "${appDir}/bin/qemu-system-x86_64" | grep " => /" | cut -d" " -f3)
linkedLibs+=$(ldd "${appDir}/bin/qemu-img" | grep " => /" | cut -d" " -f3)
for lib in $(echo ${linkedLibs} | sort | uniq ); do
  if [[ "${excludeLibs}" =~ \ $(basename ${lib})\  ]]; then
    continue
  fi
  cp "${lib}" "${appDir}/lib"
done

# strip docs
rm -rf "${appDir}/share/doc"

# remove lima agent for aarch64
rm "${appDir}/share/lima/lima-guestagent.Linux-aarch64" 

# remove qemu icons, includes, etc.
# We could fine tune the firmaware files
rm -rf "${appDir}/include"
rm -rf "${appDir}/libexec"
rm -rf "${appDir}/var"
rm -rf "${appDir}/share/applications"
rm -rf "${appDir}/share/icons"

# keep only relevant firmware
keepListedFiles "${appDir}/share/qemu" "${firmwareOfInterest}"

# keep only relevant executables
keepListedFiles "${appDir}/bin" "${executablesOfInterest}"

tar caf "${dist}.tar.gz" -C "${appDir}" .
