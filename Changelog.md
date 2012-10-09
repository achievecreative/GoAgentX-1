## GoAgnetX v1.3.5

* [NEW] 更新 goagent 到 2.0.13，请注意一定需要重新部署服务端
* [NEW] 在代理设置标签中显示当前内置 PAC 服务地址
* [NEW] goagent 和 SSH 支持断线后自动重连
* [FIX] 修正应用 PAC 域名列表时会修改代理设置的问题

*Released on 2012.10.09*

## GoAgentX v1.3.3

* [NEW] 更新 goagent 到 2.0.2，请注意一定需要重新部署服务端
* [NEW] 增加 PHP Fetch 支持
* [NEW] 增加自定义 PAC 域名列表立即应用按钮
* [NEW] 增加指定自定义 GoAgentX PAC 服务端口功能，可以通过此功能避免 GoAgentX 随系统启动时要求输入密码的问题
* [NEW] Retina Display 支持
* [FIX] 修正自定义 PAC 域名列表导致任意网站都会使用代理的问题
* [MOD] 在切换服务菜单中隐藏 goagent 服务端部署
* [MOD] 移除 goagent golang 服务端部署

*Released on 2012.08.26*

## GoAgentX v1.3.2

* [NEW] SSH 服务支持指定私钥
* [FIX] 修正在 Mountain Lion 下反复要求提权的问题

此版本由 [qqshfox](https://github.com/qqshfox) 贡献。

*Released on 2012.08.21*

## GoAgentX v1.3.0

* [NEW] 支持自定义 PAC 域名列表
* [NEW] 支持部署 golang 版本 goagent 服务端
* [NEW] 添加导入 goagent 根证书功能
* [MOD] 更新 goagent 到 1.8.11
* [MOD] 更新 west-chamber 到 2012.07.09
* [MOD] 调整代理切换界面

*Released on 2012.07.10*

## GoAgentX v1.2.0

* [NEW] 集成 SSH 服务
* [NEW] 集成 stunnel 服务
* [NEW] 添加菜单栏图标切换服务功能
* [NEW] 添加菜单栏图标切换使用 PAC 和不使用 PAC 功能
* [FIX] 修正自动切换 PAC 时在 Safari 下不工作的 bug
* [FIX] 修正不使用 PAC 时没有设置 HTTPS 代理的 bug
* [FIX] 修正停止服务时，没有恢复代理设置为原始设置的 bug
* [MOD] 更新 goagent 到 1.8.5 稳定版
* [MOD] 更新西厢第3季到 20120505

*Released on 2012.05.07*

## GoAgentX v1.1.0

* [NEW] 集成 goagent 1.8.4，不再需要单独下载
* [NEW] 集成 west-chamber-season-3 20120428
* [NEW] 集成 PAC 支持

*Released on 2012.04.28*


## GoAgentX v1.0.5

* [NEW] 兼容 goagent 1.8.3
* [NEW] 添加自动更新支持
* [NEW] 增加 PPPoE 拨号的 PAC 自动设置支持
* [NEW] 支持自定义 PAC 地址

*Released on 2012.04.20*

## GoAgentX v1.0.4

* [NEW] 增加对 goagent v1.8.0 稳定版的兼容
* [NEW] 增加自动设置系统代理为 PAC 的选项
* [NEW] 增加 CRLF Injection 设置的选项
* [FIX] 修正自动设置代理时，以太网连接的代理可能没有正确设置的问题

*Released on 2012.04.07*

## GoAgentX v1.0.3

* [NEW] 增加 GoAgentX 启动时自动设置系统代理的功能

*Released on 2012.04.05*

## GoAgentX v1.0.2

* [NEW] 增加直接程序内设置 GoAgnetX 随用户登录启动功能

*Released on 2012.02.19*

## GoAgentX v1.0.1

* [FIX] 安装 goagent 总是失败

*Released on 2012.02.16*

## GoAgentX v1.0

* 首次发布

*Released on 2012.02.15*
