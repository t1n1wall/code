#!/usr/local/bin/bash

set -e

if [ -z "$MW_BUILDPATH" -o ! -d "$MW_BUILDPATH" ]; then
	echo "\$MW_BUILDPATH is not set"
	exit 1
fi

# make our own copy of the kernel tree
		rm -Rf $MW_BUILDPATH/tmp/sys
		echo -n "Copying kernel sources..."
		cp -Rp /usr/src/sys $MW_BUILDPATH/tmp
		echo "done."

# patch kernel / sources
		cd $MW_BUILDPATH/tmp
# apuled kern/189772
		mkdir apuled
		cd apuled
		tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/apuled.tgz
		mkdir $MW_BUILDPATH/tmp/sys/dev/apuled
		mkdir $MW_BUILDPATH/tmp/sys/modules/apuled 
		cp apuled.c $MW_BUILDPATH/tmp/sys/dev/apuled
		cp Makefile $MW_BUILDPATH/tmp/sys/modules/apuled
		echo "dev/apuled/apuled.c             optional apuled" >> $MW_BUILDPATH/tmp/sys/conf/files.i386
		echo "dev/apuled/apuled.c             optional apuled" >> $MW_BUILDPATH/tmp/sys/conf/files.amd64
		cd $MW_BUILDPATH/tmp
		rm -rf apuled
#  6RD support
#		patch -p0 < $MW_BUILDPATH/freebsd10/build/patches/kernel/stf_6rd_20100923-1.diff , 6RD not used yet
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/Makefile.orig.patch
#
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/options.orig.patch
#
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/ip_ftp_pxy.c.orig.patch
# NAT redirect fix
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/ip_nat.c.orig.patch
# Not really sure what this was for, don't think we need this anymore
#		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/fil.c.orig.patch. 
#
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/mlfk_ipl.c.orig.patch
# change order of calls to ipfw to ensure ipnat works
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/pfil.c.orig.patch 
# Fix for psuedo checksum NIC's
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/ip_fil_freebsd.c.patch
# Fix for using dummynet and ipnat
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/dummynet_with_ipnat.patch
#
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/vm_machdep.c.patch
# fix for noika ip120 intel nic
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/if_em.c.patch
#
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/if_fxp.c.patch
# glxsb crypto speed increase kern/132622
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/glxsb.c.orig.patch
# ipsec patch for l2tp to work
		patch < $MW_BUILDPATH/freebsd10/build/patches/kernel/ipsec-tools.kern146190.patch
		
# kernel compile
        cd $MW_BUILDPATH/tmp/sys/$MW_ARCH/conf
        cp $MW_BUILDPATH/freebsd10/build/kernelconfigs/T1N1WALL_GENERIC.$MW_ARCH $MW_BUILDPATH/tmp/sys/$MW_ARCH/conf/T1N1WALL_GENERIC
		cp $MW_BUILDPATH/freebsd10/build/kernelconfigs/T1N1WALL_GENERIC.hints $MW_BUILDPATH/tmp/sys/$MW_ARCH/conf/
        config T1N1WALL_GENERIC
        cd $MW_BUILDPATH/tmp/sys/$MW_ARCH/compile/T1N1WALL_GENERIC/
        make depend && make
        strip kernel
        strip --remove-section=.note --remove-section=.comment kernel
        gzip -9 kernel
        mv kernel.gz $MW_BUILDPATH/tmp/
        cd modules/$MW_BUILDPATH/tmp/sys/modules
        cp -v aesni/aesni.ko glxsb/glxsb.ko padlock/padlock.ko if_tap/if_tap.ko if_vlan/if_vlan.ko dummynet/dummynet.ko ipfw/ipfw.ko $MW_BUILDPATH/t1n1fs/boot/kernel

echo "Finished Stage 5"
