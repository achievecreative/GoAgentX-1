#!/bin/sh
GOAGENT_URL="https://goo.gl/sxgfB"
if [ "$APP_BUNDLE_PATH" == "" ]; then
	APP_BUNDLE_PATH="/Applications/GoAgentX.app"
fi
if [ "$GOAGENT_FOLDER" == "" ]; then
	GOAGENT_FOLDER="$APP_BUNDLE_PATH/Contents/Resources"
fi

clean() {
	rm -rf $1/server/php/
	rm $1/server/uploader.bat

	rm $1/local/certs/*
	rm $1/local/Microsoft.VC90.CRT.manifest
	rm $1/local/SwitchyOptions.bak
	rm $1/local/SwitchySharp_1_9_52.crx
	rm $1/local/addto-startup.py
	rm $1/local/addto-startup.vbs
	rm $1/local/goagent-gtk.py
	rm $1/local/goagent.exe
	rm $1/local/msvcr90.dll
	rm $1/local/proxy.bat
	rm $1/local/python27.dll
	rm $1/local/python27.exe
	rm $1/local/uvent.bat
}

echo 正在下载 goagent ...
curl -L -o goagent.zip $GOAGENT_URL

echo 解压 goagent.zip ...
unzip goagent.zip
rm goagent.zip

echo 更新 goagent ...
folder=`ls | grep -m 1 goagent-`
clean $folder
cp -r $folder/local/* "$GOAGENT_FOLDER/goagent"
cp -r $folder/server/* "$GOAGENT_FOLDER/goagent-server"

echo 更新完成.
echo goagent 客户端代码版本：
grep -m 1 __version__ $folder/local/proxy.py
echo goagent 服务端代码版本：
grep -m 1 __version__ $folder/server/python/wsgi.py

rm -r $folder
