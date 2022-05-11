#!/bin/bash


#make CC=rpi-gcc AR="rpi-gcc --exec ar" RANLIB="rpi-gcc --exec ranlib" STRIP="rpi-gcc --exec strip" CFLAGS="-I/usr/local/tt/usr/include"

source ~/.bashrc
prepend_path /opt/pi/cross-pi-gcc-10.2.0-2/bin


build_main(){
	export CFLAGS="-I/usr/local/tt/usr/include -g -Wall -Os"
	export LDFLAGS="-L/usr/local/tt/usr/lib  -L/usr/local/tt/usr/lib/arm-linux-gnueabihf -g"

	cat options.h | sed -e 's!/etc/dropbear/!/data/etc/dropbear/!' | sed -e 's!/usr/bin/dbclient!/data/bin/dbclient!'   > options.h.1
	if diff options.h options.h.1 ; then
		rm -f options.h.1
	else
		mv options.h.1 options.h
	fi

	./configure --host=arm-linux-gnueabihf  --prefix=/data 
	make -j$(nproc)
	unset CFLAGS
	unset LDFLAGS
}

xmake(){
	rm -f "$1"
	CMD=`make "$1" CC="arm-linux-gnueabihf-gcc -v" 2>&1 | grep 'collect2 '`
	$(echo $CMD | sed -E s'/ -lgcc_s / XXX\/libgcc_s.so.1 /g' | sed -E s"/ -lc / $2 XXX\/libc.so /g") 
}

pi_build(){
	make hack_pi1.o
	make -f Makefile.hack_pi all
	make scp

	xmake scp
	xmake dbclient
	xmake dropbear hack_pi1.o
	xmake dropbearkey
}

if [ "$(type -t $1)" = "function" ] ; then
	shift
	"$@"
else
	build_main
	pi_build
fi
