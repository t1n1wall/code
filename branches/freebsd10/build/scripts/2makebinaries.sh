#!/usr/local/bin/bash

set -e

if [ -z "$MW_BUILDPATH" -o ! -d "$MW_BUILDPATH" ]; then
	echo "\$MW_BUILDPATH is not set"
	exit 1
fi

export CC=gcc46

# set working directory etc for ports compilation
	rm -Rf $MW_BUILDPATH/tmp/ports/work
	mkdir -p $MW_BUILDPATH/tmp/ports/work
        export PORTSDIR=$MW_BUILDPATH/tmp/ports/tree
# set port options for ports that need user input
	rm -Rf $MW_BUILDPATH/tmp/ports/db
	mkdir -p $MW_BUILDPATH/tmp/ports/db
	export PORT_DBDIR=$MW_BUILDPATH/tmp/ports/db
	
	for portoptf in $MW_BUILDPATH/freebsd10/build/files/portoptions/* ; do
		port=${portoptf##*/}
		mkdir -p $PORT_DBDIR/$port
		cp $portoptf $PORT_DBDIR/$port/options
	done


######## manually compiled packages ########

# select Autoconf version 2.13
		export AUTOCONF_VERSION=2.13
# php 4.4.9
	cd $MW_BUILDPATH/tmp
	rm -Rf php-4.4.9
        tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/php-4.4.9.tar.bz2
        cd php-4.4.9/ext/
	tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/radius-1.2.5.tgz
        mv radius-1.2.5 radius
        cd ..
	rm configure
        AUTOCONF_VERSION=2.13 ./buildconf --force
        ./configure --without-mysql --with-pear --with-openssl --enable-discard-path --enable-radius --enable-sockets --enable-bcmath
        patch < $MW_BUILDPATH/freebsd10/build/patches/packages/php.openssl.c.patch
        make
        install -s sapi/cgi/php $MW_BUILDPATH/t1n1fs/usr/local/bin/
# mini httpd
        cd $MW_BUILDPATH/tmp
        rm -Rf mini_httpd-1.21
        tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/mini_httpd-1.21.tar.gz
        cd mini_httpd-1.21/
        patch < $MW_BUILDPATH/freebsd10/build/patches/packages/mini_httpd.patch
        make
        install -s mini_httpd $MW_BUILDPATH/t1n1fs/usr/local/sbin
# ezipupdate
        cd $MW_BUILDPATH/tmp
	rm -Rf ez-ipupdate-3.0.11b8
        tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/ez-ipupdate-3.0.11b8.tar.gz
        cd ez-ipupdate-3.0.11b8
        patch < $MW_BUILDPATH/freebsd10/build/patches/packages/ez-ipupdate.c.patch
        ./configure
        make
        install -s ez-ipupdate $MW_BUILDPATH/t1n1fs/usr/local/bin/
# ipfilter userland tools
        export CC=cc
        cd /sbin
        cp ipf ipfs ipmon ipnat ippool $MW_BUILDPATH/t1n1fs/sbin
        cd /usr/src/contrib/ipfilter/tools/
        cp ipfstat.c ipfstat.c.original
        patch < $MW_BUILDPATH/freebsd10/build/patches/user/ipfstat.c.patch
        cd /usr/src/sbin/ipf/
        make clean
	make libipf ipfstat ipf ipfs ipmon ipnat ippool 
        cp /usr/src/sbin/ipf/ipfstat/ipfstat $MW_BUILDPATH/t1n1fs/sbin
        cd /usr/src/contrib/ipfilter/tools/
        cp ipfstat.c.original ipfstat.c
	export CC=gcc46
# modem-stats
	cd $MW_BUILDPATH/tmp
	rm -Rf modem-stats-1.0.1
        tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/modem-stats-1.0.1.src.elf.tar.gz
	cd modem-stats-1.0.1
	patch < $MW_BUILDPATH/freebsd10/build/patches/user/modem-stats.c.patch
	make
	install -s modem-stats $MW_BUILDPATH/t1n1fs/sbin
# dnsmasq
        cd $MW_BUILDPATH/tmp
        rm -Rf dnsmasq-2.66
        tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/dnsmasq-2.66.tar.gz
        cd dnsmasq-2.66
        cp $MW_BUILDPATH/freebsd10/build/patches/packages/patch-dnsmasq-iscreader.patch .
        patch < patch-dnsmasq-iscreader.patch
        make COPTS=-DNO_DHCPv6 COPTS+=-DNO_AUTH COPTS+=-DNO_TFTP COPTS+=-DNO_SCRIPT COPTS+=-DNO_LARGEFILE COPTS+=-DNO_DHCP6
        install -s src/dnsmasq $MW_BUILDPATH/t1n1fs/usr/local/sbin
        rm patch-dnsmasq-iscreader.patch
# dudders
        cd $MW_BUILDPATH/tmp
        rm -Rf dudders-1.04
        tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/dudders-1.04.tar.bz2
        cd dudders-1.04
        ./configure --with-crypto=openssl
        make
        install -s dudders $MW_BUILDPATH/t1n1fs/usr/local/bin
        
######## FreeBSD ports ########
# ntpd
        export CC=cc
 	cd $PORTSDIR/net/openntpd
        make CONFIGURE_ARGS=--with-privsep-user=root MASTER_SITE_OVERRIDE=http://ftp.heanet.ie/mirrors/OpenBSD/OpenNTPD/
	export CC=gcc46
# ISC dhcp-server
        cd $PORTSDIR/net/isc-dhcp41-server
        cp $MW_BUILDPATH/freebsd10/build/patches/packages/isc-dhcpd/patch-server.db.c files/
        make
        install -s $WRKDIRPREFIX/$PORTSDIR/net/isc-dhcp41-server/work/dhcp-*/server/dhcpd $MW_BUILDPATH/t1n1fs/usr/local/sbin/
        rm files/patch-server.db.c
# ISC dhcp-client
        cd $PORTSDIR/net/isc-dhcp41-client
        make
        install -s $WRKDIRPREFIX/$PORTSDIR/net/isc-dhcp41-client/work/dhcp-*/client/dhclient $MW_BUILDPATH/t1n1fs/sbin/
# ISC dhcp-relay
        cd $PORTSDIR/net/isc-dhcp41-relay
        make
        install -s $WRKDIRPREFIX/$PORTSDIR/net/isc-dhcp41-relay/work/dhcp-*/relay/dhcrelay $MW_BUILDPATH/t1n1fs/usr/local/sbin/
# ipsec-tools
        cd $PORTSDIR/security/ipsec-tools
        patch < $MW_BUILDPATH/freebsd10/build/patches/packages/ipsec-tools.Makefile.patch
        cp $MW_BUILDPATH/freebsd10/build/patches/packages/ipsec-tools.wildcard.patch $PORTSDIR/security/ipsec-tools/files
        cp $MW_BUILDPATH/freebsd10/build/patches/packages/ipsec-tools.fqdn.patch $PORTSDIR/security/ipsec-tools/files
        cp $MW_BUILDPATH/freebsd10/build/patches/packages/ipsec-tools.patch-zz-local-3.diff $PORTSDIR/security/ipsec-tools/files
        cp $MW_BUILDPATH/freebsd10/build/patches/packages/ipsec-tools.kern146190_NATOa.patch $PORTSDIR/security/ipsec-tools/files        
        make
        install -s $WRKDIRPREFIX/$PORTSDIR/security/ipsec-tools/work/ipsec-tools-*/src/racoon/.libs/racoon $MW_BUILDPATH/t1n1fs/usr/local/sbin
        install -s $WRKDIRPREFIX/$PORTSDIR/security/ipsec-tools/work/ipsec-tools-*/src/setkey/.libs/setkey $MW_BUILDPATH/t1n1fs/usr/local/sbin
        install -s $WRKDIRPREFIX/$PORTSDIR/security/ipsec-tools/work/ipsec-tools-*/src/libipsec/.libs/libipsec.so.0 $MW_BUILDPATH/t1n1fs/usr/local/lib
        mv Makefile.orig Makefile
# dhcp6
	cd $PORTSDIR/net/dhcp6
        make
	install -s $WRKDIRPREFIX/$PORTSDIR/net/dhcp6/work/wide-dhc*/dhcp6c $MW_BUILDPATH/t1n1fs/usr/local/sbin
	install -s $WRKDIRPREFIX/$PORTSDIR/net/dhcp6/work/wide-dhc*/dhcp6s $MW_BUILDPATH/t1n1fs/usr/local/sbin
# sixxs-aiccu		
	cd $PORTSDIR/net/sixxs-aiccu
	cp $MW_BUILDPATH/freebsd10/build/patches/packages/patch-aiccu-common.c files/
	cp -p Makefile Makefile.orig
	patch -l < $MW_BUILDPATH/freebsd10/build/patches/packages/sixxs-aiccu.Makefile.patch
        make
	install -s $WRKDIRPREFIX/$PORTSDIR/net/sixxs-aiccu/work/aiccu/unix-console/aiccu $MW_BUILDPATH/t1n1fs/usr/local/sbin/sixxs-aiccu
	mv Makefile.orig Makefile
	rm files/patch-aiccu-common.c
# mpd5
	cd $PORTSDIR/net/mpd5
        make
	install -s $WRKDIRPREFIX/$PORTSDIR/net/mpd5/work/mpd-*/src/mpd5 $MW_BUILDPATH/t1n1fs/usr/local/sbin/
# xmbmon
	cd $PORTSDIR/sysutils/xmbmon
        make
	install -s $WRKDIRPREFIX/$PORTSDIR/sysutils/xmbmon/work/xmbmon*/mbmon $MW_BUILDPATH/t1n1fs/usr/local/bin/
# wol
	cd $PORTSDIR/net/wol
	make WITHOUT=NLS
        install -s $WRKDIRPREFIX/$PORTSDIR/net/wol/work/wol-*/src/wol $MW_BUILDPATH/t1n1fs/usr/local/bin/


# make t1n1wall tools and binaries
        cd $MW_BUILDPATH/tmp
        cp -r $MW_BUILDPATH/freebsd10/build/tools .
        cd tools
        gcc -o stats.cgi stats.c
        gcc -o minicron minicron.c
        gcc -o choparp choparp.c
        gcc -o verifysig -lcrypto verifysig.c
        gcc -o dnswatch dnswatch.c
        gcc -o voucher -lcrypto voucher.c
        gcc -o croen croen.c
	cc -pthread -o ledindicator  ledindicator.c 
        install -s choparp $MW_BUILDPATH/t1n1fs/usr/local/sbin
        install -s stats.cgi $MW_BUILDPATH/t1n1fs/usr/local/www
        install -s minicron $MW_BUILDPATH/t1n1fs//usr/local/bin
        install -s verifysig $MW_BUILDPATH/t1n1fs/usr/local/bin
        install -s dnswatch $MW_BUILDPATH/t1n1fs/usr/local/bin
        install -s voucher $MW_BUILDPATH/t1n1fs/usr/local/bin
        install -s croen $MW_BUILDPATH/t1n1fs/usr/local/bin
	install -s ledindicator $MW_BUILDPATH/t1n1fs/usr/local/sbin
        install ppp-linkup vpn-linkdown vpn-linkup $MW_BUILDPATH/t1n1fs/usr/local/sbin

# select Autoconf version 2.62
#		export AUTOCONF_VERSION=2.62
# net-snmp
        cd $MW_BUILDPATH/tmp
        rm -Rf net-snmp-5.7.3
        tar -zxf $MW_BUILDPATH/freebsd10/build/local-sources/net-snmp-5.7.3.tar.gz
        cd net-snmp-5.7.3
        ./configure --with-sys-contact="contact" --with-sys-location="location" --without-openssl --with-default-snmp-version="2" \
        --enable-ipv6 --disable-set-support --disable-des --disable-privacy --disable-md5 --disable-debugging --enable-mini-agent --disable-testing-code \
        --disable-shared-version --disable-shared '--with-out-transports=TCP Unix TCPIPv6 Callback'  '--with-mib-modules=if-mib host mibII/var_route ucd_snmp' \
        --enable-mfd-rewrites --with-defaults
	make
        install -s agent/snmpd $MW_BUILDPATH/t1n1fs/usr/local/sbin

echo "Finished Stage 2"
