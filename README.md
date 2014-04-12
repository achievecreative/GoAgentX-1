# GoAgentX

GoAgentX 是一个在 Mac OS X 下使用代理服务的图形界面控制软件，方便一般用户在 Mac OS X 上配置和使用 goagent、west-chamber-season-3、SSH、stunnel 及 shadowsocks。

## 下载

<https://github.com/ohdarling/GoAgentX/releases>

## 功能

* 支持 goagent，west-chamber-season-3，SSH，stunnel，shadowsocks
* 支持部署 goagent 服务端到 App Engine
* 自动设置系统 HTTP 代理或者 PAC 设置
* 集成 goagent 与 west-chamber-season-3
* 图形化界面设置客户端连接参数
* 菜单栏图标，直接控制连接状态
* 菜单栏快速切换服务以及是否使用 PAC
* 用户登录时自动启动代理服务

## 要求

* Mac OS X 10.6 及以上版本系统
* 支持 64 位的 Intel CPU

## 如何使用

### goagent

关于 goagent 的介绍请参见 <http://code.google.com/p/goagent/>。

1. 申请 Google App Engine 并创建 appid
1. 下载 GoAgentX <https://github.com/ohdarling/GoAgentX/downloads>
1. 进入 GoAgentX 服务设置标签，选择“goagent 服务端”，填写相关信息后，进入状态标签页点击启动来部署 goagent 到 App Engine
1. 进入 GoAgentX 服务设置标签，选择“goagent”，填写之前申请的 App Engine appid 以及服务密码，并根据实际情况选择连接方式和服务器
1. 进入 GoAgentX 状态标签，选择服务为 goagent，点击启动，如果显示启动成功则可以开始使用

其他相关情况请参见 [goagent 简易教程](http://code.google.com/p/goagent/#简易教程)

### 西厢第3季

关于 west-chamber-season-3 请参见 <https://github.com/liruqi/west-chamber-season-3>。

进入状态标签页，选择服务为“西厢第3季”，点击启动即可。

### SSH

1. 进入服务配置标签页，并选择 SSH，填入 SSH 服务相关信息。
1. 进入状态标签页，选择 SSH，点击启动

### Stunnel

关于 stunnel 请参见 <http://www.stunnel.org/>。

服务端配置请参考 <https://www.google.com/search?q=stunnel+代理>。

### shadowsocks

关于 shadowsocks 请参见 <https://github.com/clowwindy/shadowsocks>。


## 程序截图

![程序截图](https://github.com/ohdarling/GoAgentX/raw/master/Screenshot.png)

## 如何编译

获取代码：

    git clone https://github.com/ohdarling/GoAgentX
    git submodule init
    git submodule update

然后打开 Xcode 项目 GoAgentX.xcodeproj 进行编译即可。

## 如何提问题

进入 <https://github.com/ohdarling/GoAgentX/issues/new> 页面填写需求信息或 Bug 即可。

当然，你也可以 fork 这个项目，修改后申请 Pull Request，我会尽快合并。

## 相关链接

* [goagent](http://code.google.com/p/goagent/)
* [Google App Engine](https://appengine.google.com/)
* [west-chamber-season-3](https://github.com/liruqi/west-chamber-season-3)
* [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer)
* [stunnel](http://www.stunnel.org/)
* [shadowsocks](https://github.com/clowwindy/shadowsocks)

## 关于

你可以在 Twitter 上关注我：[@ohdarling88](http://twitter.com/ohdarling88)

## 许可

GoAgentX 代码使用 BSD-2 许可证，此外不允许将软件以完整二进制的方式进行公开发行（例如上传到 App Store 发布）。

    Copyright (c) 2012, Jiwei Xu
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
    OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

* goagent 协议：[GNU GPL v2](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
* stunnel 协议：[GPL](https://www.stunnel.org/sdf_copying.html)
