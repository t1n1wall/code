#!/usr/local/bin/bash

set -e

if [ -z "$MW_BUILDPATH" -o ! -d "$MW_BUILDPATH" ]; then
	echo "\$MW_BUILDPATH is not set"
	exit 1
fi

export CC=cc

# crunch !
	# patch dnsmasq Makefile, consider a Makefile header ?
	cp $MW_BUILDPATH/tmp/dnsmasq-2.66/Makefile /usr/t1n1wall/build10/tmp/dnsmasq-2.66/src/
	echo "depend:" >> $MW_BUILDPATH/tmp/dnsmasq-2.66/src/Makefile
	echo "depend:" >> $MW_BUILDPATH/tmp/ports/tree/security/ipsec-tools/work/ipsec-tools-0.8.2/src/setkey/Makefile
	echo "depend:" >> $MW_BUILDPATH/tmp/ports/tree/security/ipsec-tools/work/ipsec-tools-0.8.2/src/racoon/Makefile
	echo "depend:" >> $MW_BUILDPATH/tmp/modem-stats-1.0.1/Makefile
	echo "depend:" >> $MW_BUILDPATH/tmp/dudders-1.04/Makefile
	echo "depend:" >> $MW_BUILDPATH/tmp/php-4.4.9/Makefile
	echo "depend:" >> $MW_BUILDPATH/tmp/ez-ipupdate-3.0.11b8/Makefile
#build some stuff that crunchgen doesn't build right
	cd /usr/src/sbin/camcontrol && /usr/bin/make 	
	cd /usr/src/sbin/ipfw && /usr/bin/make 	
	cd /usr/src/sbin/ping6 && /usr/bin/make 	
	cd /usr/src/sbin/reboot && /usr/bin/make 	
	cd /usr/src/sbin/sysctl && /usr/bin/make 	
	cd /usr/src/usr.sbin/traceroute && /usr/bin/make  
	cd $MW_BUILDPATH/tmp/modem-stats-1.0.1
        cc -g -O -c modem-stats.c
	# now crunch
	cd $MW_BUILDPATH/tmp
	rm -rf crunchgen
	mkdir crunchgen
	cd crunchgen
	cp $MW_BUILDPATH/freebsd10/build/minibsd/t1n1box.conf .
	export CC=gcc46
	/usr/bin/crunchgen -f t1n1box.conf
	/usr/bin/make -f t1n1box.mk objs exe
	install -s t1n1box $MW_BUILDPATH/t1n1fs/bin/

	# clean up
	cd /usr/src/sbin/camcontrol && /usr/bin/make clean
	cd /usr/src/sbin/ipfw && /usr/bin/make clean
	cd /usr/src/sbin/ping6 && /usr/bin/make clean
	cd /usr/src/sbin/reboot && /usr/bin/make clean
	cd /usr/src/sbin/sysctl && /usr/bin/make clean
	cd /usr/src/usr.sbin/traceroute && /usr/bin/make clean
	cd $MW_BUILDPATH/tmp

# remove files that were put in by stage 2 and are now part of crunched binary
	rm -rf $MW_BUILDPATH/t1n1fs/usr/local/sbin/dnsmasq
	rm -rf $MW_BUILDPATH/t1n1fs/usr/local/sbin/setkey
	rm -rf $MW_BUILDPATH/t1n1fs/usr/local/sbin/racoon
	rm -rf $MW_BUILDPATH/t1n1fs/usr/local/lib/libipsec.so.0
	rm -rf $MW_BUILDPATH/t1n1fs/usr/local/bin/dudders
	rm -rf $MW_BUILDPATH/t1n1fs/usr/local/bin/ez-ipupdate
	rm -rf $MW_BUILDPATH/t1n1fs/sbin/modem-stats
	rm -rf $MW_BUILDPATH/t1n1fs/sbin/ipf
	rm -rf $MW_BUILDPATH/t1n1fs/sbin/ipfs
	rm -rf $MW_BUILDPATH/t1n1fs/sbin/ipmon
	rm -rf $MW_BUILDPATH/t1n1fs/sbin/ipnat
	rm -rf $MW_BUILDPATH/t1n1fs/sbin/ippool 
	rm -rf $MW_BUILDPATH/t1n1fs/sbin/ipfstat
	rm -rf $MW_BUILDPATH/t1n1fs/usr/local/sbin/mpd5
#
	cd $MW_BUILDPATH/tmp
	perl $MW_BUILDPATH/freebsd10/build/minibsd/mkmini.pl $MW_BUILDPATH/freebsd10/build/minibsd/t1n1wall.files  / $MW_BUILDPATH/t1n1fs/
	perl $MW_BUILDPATH/freebsd10/build/minibsd/mkmini.pl $MW_BUILDPATH/freebsd10/build/minibsd/t1n1box.files  / $MW_BUILDPATH/t1n1fs/

# make libs
	cd $MW_BUILDPATH/tmp
	perl $MW_BUILDPATH/freebsd10/build/minibsd/mklibs.pl $MW_BUILDPATH/t1n1fs > t1n1wall.libs
	perl $MW_BUILDPATH/freebsd10/build/minibsd/mkmini.pl t1n1wall.libs / $MW_BUILDPATH/t1n1fs

echo "Finished Stage 4.5"
