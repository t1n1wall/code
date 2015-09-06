#!/bin/csh 

set MW_BUILDPATH=/usr/t1n1wall/build10
setenv MW_BUILDPATH $MW_BUILDPATH
setenv MW_ARCH `uname -m`

# ensure prerequisite tools are installed
if ( ! -x /usr/local/bin/bash ) then
	pkg install -y -g 'bash-4.*'
endif

# figure out if we're already running from within a repository
set svnliteinfo=`/usr/bin/svnlite info freebsd10 >& /dev/null`
if  ( $status != 1 ) then
	echo "Found existing working copy"
else
	echo "No working copy found; checking out current version from repository"
	/usr/bin/svnlite checkout https://svn.code.sf.net/p/t1n1wall/code/branches/freebsd10/
endif

cd freebsd10

echo "Creating build directory $MW_BUILDPATH."
mkdir -p $MW_BUILDPATH

echo "Exporting repository to $MW_BUILDPATH/freebsd10."
/usr/bin/svnlite export --force . $MW_BUILDPATH/freebsd10
/usr/bin/svnliteversion -n . > $MW_BUILDPATH/freebsd10/svnrevision

echo "Changing directory to $MW_BUILDPATH/freebsd10/build/scripts"
cd $MW_BUILDPATH/freebsd10/build/scripts
chmod +x *.sh

echo "Updating ports to correct versions: 2013-12-20"

/usr/bin/svnlite checkout --depth empty svn://svn.freebsd.org/ports/head  $MW_BUILDPATH/tmp/ports/tree
cd $MW_BUILDPATH/tmp/ports/tree

/usr/bin/svnlite update -r '{2015-03-19}' --set-depth files Templates Tools net dns security sysutils devel GIDs UIDs Keywords
/usr/bin/svnlite update -r '{2015-03-19}' Mk net/isc-dhcp41-server/ net/isc-dhcp41-relay/ net/isc-dhcp41-client/ net/mpd5/ net/dhcp6 net/wol sysutils/xmbmon
/usr/bin/svnlite update -r '{2015-08-19}' security/ipsec-tools devel/libtool net/openntpd
/usr/bin/svnlite update -r '{2015-03-19}' net/sixxs-aiccu devel/gmake security/gnutls

cd $MW_BUILDPATH/freebsd10/build/scripts

echo 
echo "----- Build environment prepared -----"
echo "I will leave you in a bash shell now"
echo "To start the build, execute doall.sh or run 1makebuildenv.sh , then 2makebinaries.sh, then 3patchtools.sh etc"
setenv PS1 "t1n1wall-build# "
/usr/local/bin/bash
