#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1

if [ $# -ne 3 ] ; then
	[ $# -eq 1 ] && hostarch=$1 || hostarch=`uname -m | sed -e s/i.86/x86/ -e s/x86_64/x86/`
	linux_header_dir=tools/include/uapi/linux
	header_dir=tools/include/uapi/asm-generic
	arch_header_dir=tools/arch/${hostarch}/include/uapi/asm
else
	linux_header_dir=$1
	header_dir=$2
	arch_header_dir=$3
fi

linux_mman=${linux_header_dir}/mman.h
arch_mman=${arch_header_dir}/mman.h

# those in grep -Evw are flags, we want just the bits

printf "static const char *mmap_flags[] = {\n"
regex='^[[:space:]]*#[[:space:]]*define[[:space:]]+MAP_([[:alnum:]_]+)[[:space:]]+(0x[[:xdigit:]]+)[[:space:]]*.*'
grep -Eq $regex ${arch_mman} && \
(grep -E $regex ${arch_mman} | \
	sed -r "s/$regex/\2 \1/g"	| \
	xargs printf "\t[ilog2(%s) + 1] = \"%s\",\n")
grep -Eq $regex ${linux_mman} && \
(grep -E $regex ${linux_mman} | \
	grep -Evw 'MAP_(UNINITIALIZED|TYPE|SHARED_VALIDATE)' | \
	sed -r "s/$regex/\2 \1/g"	| \
	xargs printf "\t[ilog2(%s) + 1] = \"%s\",\n")
([ ! -f ${arch_mman} ] || grep -Eq '#[[:space:]]*include[[:space:]]+<uapi/asm-generic/mman.*' ${arch_mman}) &&
(grep -E $regex ${header_dir}/mman-common.h | \
	grep -Evw 'MAP_(UNINITIALIZED|TYPE|SHARED_VALIDATE)' | \
	sed -r "s/$regex/\2 \1/g"	| \
	xargs printf "\t[ilog2(%s) + 1] = \"%s\",\n")
([ ! -f ${arch_mman} ] || grep -Eq '#[[:space:]]*include[[:space:]]+<uapi/asm-generic/mman.h>.*' ${arch_mman}) &&
(grep -E $regex ${header_dir}/mman.h | \
	sed -r "s/$regex/\2 \1/g"	| \
	xargs printf "\t[ilog2(%s) + 1] = \"%s\",\n")
printf "};\n"
