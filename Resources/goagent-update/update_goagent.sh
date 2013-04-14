#!/bin/sh
GOAGENT_URL="https://goo.gl/sxgfB"
SHADOWSOCKS_URL="https://github.com/clowwindy/shadowsocks/archive/master.zip"

if [ "$APP_BUNDLE_PATH" == "" ]; then
	APP_BUNDLE_PATH="/Applications/GoAgentX.app"
fi
if [ "$SERVICES_FOLDER" == "" ]; then
	SERVICES_FOLDER="$APP_BUNDLE_PATH/Contents/Resources"
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

echo 开始更新 goagent ...
echo 正在下载 goagent ...
curl -L -o goagent.zip $GOAGENT_URL

echo 解压 goagent.zip ...
unzip goagent.zip
rm goagent.zip

goagent_folder=`ls | grep -m 1 goagent-`
clean $goagent_folder
cp -r $goagent_folder/local/* "$SERVICES_FOLDER/goagent"
cp -r $goagent_folder/server/* "$SERVICES_FOLDER/goagent-server"


# 更新 shadowsocks
echo 
echo 开始更新 shadowsocks ...
curl -L -o shadowsocks.zip $SHADOWSOCKS_URL
unzip shadowsocks.zip
rm shadowsocks.zip
ss_folder=`ls | grep -m 1 shadowsocks-`
cp -r $ss_folder/* "$SERVICES_FOLDER/shadowsocks"

# 输出结果
echo 
echo goagent 更新完成.
echo goagent 客户端代码版本：
grep -m 1 __version__ $goagent_folder/local/proxy.py
echo goagent 服务端代码版本：
grep -m 1 __version__ $goagent_folder/server/python/wsgi.py

rm -r $goagent_folder

echo 
echo shadowsocks 更新完成，版本：
grep -m 1 "Current version:" "$ss_folder/README.md"
rm -r $ss_folder