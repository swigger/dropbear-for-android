#!/bin/bash -e

#make CC=rpi-gcc AR="rpi-gcc --exec ar" RANLIB="rpi-gcc --exec ranlib" STRIP="rpi-gcc --exec strip" CFLAGS="-I/usr/local/tt/usr/include"

source ~/.bashrc
prepend_path /opt/pi/cross-pi-gcc-10.2.0-2/bin
SCRIPT_DIR=$(cd  "$(dirname "${BASH_SOURCE[0]}")" && pwd)

prepare_files(){
	mkdir -p XXX
	if [ ! -e XXX/libc.so ] ; then
		cat > XXX/libc.so <<EOF
/* GNU ld script */
OUTPUT_FORMAT(elf32-littlearm)
GROUP ( $PWD/XXX/libc.so.6 $PWD/XXX/libc_nonshared.a AS_NEEDED ( $PWD/XXX/ld-linux-armhf.so.3 ) )
EOF
	fi
	FILES="ld-linux-armhf.so.3 libc.so.6 libcrypt.so.1 libgcc_s.so.1"
	HAS_FILES=1
	for i in $FILES ; do 
		if [ ! -e XXX/$i ] ; then
			HAS_FILES=0
		fi
	done
	if [ $HAS_FILES -eq 0 ] ; then
		echo "=========== attention : run in box:  ===============" >&2
		echo "cd /lib ; tar -hcz $FILES | xxd -g 1 | nc 192.168.4.1 1023" >&2
		nc -l 8810 > files.tgz.tmp
		cat files.tgz.tmp | xxd -r | tar -xz -C XXX
	fi
}

hack_settings() {
	cat $1 | sed -e 's!"/etc/dropbear/!"/data/etc/dropbear/!' | sed -e 's!"/usr/bin/dbclient!"/data/bin/dbclient!'   > $1.tmp
	if diff $1 $1.tmp ; then
		rm -f $1.tmp
	else
		mv $1.tmp $1
	fi
}

hack_svrauth(){
	FILE=svr-authpubkey.c
	if grep sw-changed $FILE ; then
		return 0
	fi
	read -r line1 xx <<< `grep  -n '/authorized_keys' $FILE | grep -v '*' | cut -d: -f1`
	read -r line2 xx <<< `grep -n ses.authstate.pw_dir, $FILE | cut -d: -f1`
	echo $line1 $line2
	ex $FILE <<EOF
$line2 insert
if (ses.authstate.pw_uid == 0){ ret=checkfileperm("/data/etc/dropbear/authorized_keys"); goto out;} /* sw-changed */
.
$line1 insert
if (ses.authstate.pw_uid == 0){ filename=m_realloc(filename, 100); strcpy(filename, "/data/etc/dropbear/authorized_keys"); } else
.
xit
EOF
}
build_main(){
	SRCDIR=$(cd .. && pwd)
	export CFLAGS="-I/usr/local/tt/usr/include -I$SRCDIR/libtommath -g -Wall -Os" # -DDEBUG_TRACE=5"
	export LDFLAGS="-L/usr/local/tt/usr/lib  -L/usr/local/tt/usr/lib/arm-linux-gnueabihf -g"

	if [ ! -f Makefile ] ; then
		PFILE=$PWD/pubkeypos.patch
		pushd .. > /dev/null
		if [ -f default_options.h ] ; then
			hack_settings "default_options.h"
		else
			hack_settings "options.h"
		fi
		hack_svrauth
		popd > /dev/null
		prepare_files
		../configure --host=arm-linux-gnueabihf  --prefix=/data
	fi
	make -j$(nproc)
	unset CFLAGS
	unset LDFLAGS
}

bmake(){
	CMD=` "$@" -v 2>&1 | grep 'collect2 '`
	CMD1=$(echo $CMD | sed -E "s# -lgcc_s # $SCRIPT_DIR/XXX/libgcc_s.so.1 #g" | sed -E s"# -lc # $SCRIPT_DIR/hack_pi1.o $SCRIPT_DIR/XXX/libc.so #g" | sed -E "s# -lcrypt # $SCRIPT_DIR/XXX/libcrypt.so.1 #")
	echo $CMD1
	$CMD1
}

xmake(){
	rm -f "$1"
	CMD=`make "$1" CC="arm-linux-gnueabihf-gcc -v" 2>&1 | grep 'collect2 '`
	CMD1=$(echo $CMD | sed -E s"# -lgcc_s # $SCRIPT_DIR/XXX/libgcc_s.so.1 #g" | sed -E s"# -lc # $SCRIPT_DIR/hack_pi1.o $SCRIPT_DIR/XXX/libc.so #g" | sed -E s"# -lcrypt # $SCRIPT_DIR/XXX/libcrypt.so.1 #")
	echo $CMD1
	$CMD1
}

pi_build(){
	make hack_pi1.o
	make -f Makefile.hack_pi all
	make scp

	xmake scp
	xmake dbclient
	xmake dropbearkey
	xmake dropbear
}

clean(){
	make distclean || true
	rm -fr libtomcrypt libtommath test config.* *.tmp
}

if [ "$(type -t $1)" = "function" ] ; then
	"$@"
else
	build_main
	pi_build
fi
