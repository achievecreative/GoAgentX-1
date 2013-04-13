#!/bin/sh

PROGNAME=$(basename $0)

usage() {
	echo "usage: $PROGNAME [ goagent dir ]"
}

clean() {
	rm -rf goagent-server/php/
	rm goagent/certs/*
	rm goagent-server/uploader.bat
	rm goagent/Microsoft.VC90.CRT.manifest
	rm goagent/SwitchyOptions.bak
	rm goagent/SwitchySharp_1_9_52.crx
	rm goagent/addto-startup.py
	rm goagent/addto-startup.vbs
	rm goagent/goagent-gtk.py
	rm goagent/goagent.exe
	rm goagent/msvcr90.dll
	rm goagent/proxy.bat
	rm goagent/python27.dll
	rm goagent/python27.exe
	rm goagent/uvent.bat
}


if [[ -n $1 ]]; then
	echo $1
	cp -r $1/local/* ./goagent/
	cp -r $1/server/* ./goagent-server/

	clean
else
	usage
	exit 1
fi
