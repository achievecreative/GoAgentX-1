//
//  GAAppDelegate.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-2-13.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAAppDelegate.h"


@implementation GAAppDelegate

@synthesize window = _window;

#pragma mark -
#pragma mark Helper

- (NSString *)pathInApplicationSupportFolder:(NSString *)path {
    NSString *folder = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                         stringByAppendingPathComponent:@"Application Support"]
                        stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
    return [folder stringByAppendingPathComponent:path];
}


- (NSString *)copyFolderToApplicationSupport:(NSString *)folder {
    NSString *srcPath = [[self pathInApplicationSupportFolder:@"goagent"] stringByAppendingPathComponent:folder];
    NSString *copyPath = [self pathInApplicationSupportFolder:folder];
    [[NSFileManager defaultManager] removeItemAtPath:copyPath error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:[copyPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:copyPath error:NULL];
    return copyPath;
}


- (NSString *)copyServerToApplicationSupport {
    return [self copyFolderToApplicationSupport:@"server"];
}


- (NSString *)copyLocalToApplicationSupport {
    return [self copyFolderToApplicationSupport:@"local"];
}


- (NSDictionary *)defaultSettings {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GoAgentDefaultSettings" ofType:@"plist"]];
    return dict;
}


- (void)setStatusToRunning:(NSNumber *)status {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setStatusToRunning:) withObject:status waitUntilDone:[NSThread isMainThread]];
        return;
    }
    
    BOOL running = [status boolValue];
    
    NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:Local:Port"];
    NSString *statusText = [NSString stringWithFormat:@"正在运行，端口 %ld", port];
    NSImage *statusImage = [NSImage imageNamed:@"status_running"];
    NSString *buttonTitle = @"停止";
    
    if (!running) {
        statusText = @"已停止";
        statusImage = [NSImage imageNamed:@"status_stopped"];
        buttonTitle = @"启动";
        [statusLogTextView appendString:@"服务已停止\n"];
    }
    
    statusBarItem.toolTip = statusText;
    statusTextLabel.stringValue = statusText;
    statusImageView.image = statusImage;
    statusMenuItem.title = statusText;
    statusMenuItem.image = statusImage;
    statusToggleButton.title = buttonTitle;
    
    // 自动切换系统代理设置
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:AutoToggleSystemProxySettings"]) {
        [self setSystemProxySettingsToGoAgent:running];
    }
}

- (NSArray *)connectionModes {
    return [NSArray arrayWithObjects:@"HTTP", @"HTTPS", nil];
}


- (NSArray *)gaeProfiles {
    return [NSArray arrayWithObjects:@"google_cn", @"google_hk", @"google_ipv6", nil];;
}


#pragma mark -
#pragma mark Setup

- (void)setupStatusItem {
    statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:23.0];
    statusBarItem.image = [NSImage imageNamed:@"status_item_icon"];
    statusBarItem.alternateImage = [NSImage imageNamed:@"status_item_icon_alt"];
    statusBarItem.menu = statusBarItemMenu;
    statusBarItem.toolTip = @"GoAgent is NOT Running";
    [statusBarItem setHighlightMode:YES];
}


- (BOOL)checkIfGoAgentInstalled {
    NSString *goagentPath = [self pathInApplicationSupportFolder:@"goagent"];
    NSString *proxypyPath  = [[goagentPath stringByAppendingPathComponent:@"local"] stringByAppendingPathComponent:@"proxy.py"];
    NSString *fetchpyPath = [[[goagentPath stringByAppendingPathComponent:@"server"] stringByAppendingPathComponent:@"python"] stringByAppendingPathComponent:@"fetch.py"];
    return [[NSFileManager defaultManager] fileExistsAtPath:proxypyPath] && [[NSFileManager defaultManager] fileExistsAtPath:fetchpyPath];
}


- (void)installFromFolder:(NSString *)path {
    NSString *goagentPath = [self pathInApplicationSupportFolder:@"goagent"];
    [[NSFileManager defaultManager] removeItemAtPath:goagentPath error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:goagentPath withIntermediateDirectories:YES attributes:nil error:NULL];
    
    [[NSFileManager defaultManager] copyItemAtPath:[path stringByAppendingPathComponent:@"local"]
                                            toPath:[goagentPath stringByAppendingPathComponent:@"local"] error:NULL];
    
    [[NSFileManager defaultManager] copyItemAtPath:[path stringByAppendingPathComponent:@"server"]
                                            toPath:[goagentPath stringByAppendingPathComponent:@"server"] error:NULL];
}


- (void)showInstallPanel:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"尚未安装 goagent"
                                     defaultButton:@"前往下载页面"
                                   alternateButton:@"我已经下载了最新的 goagent"
                                       otherButton:nil
                         informativeTextWithFormat:@"如果您尚未下载过 goagent，请点击“前往下载页面”。下载后将压缩包解压，"
                      "目录中将会有 local 和 server 两个目录，在下一步的选择框中请选择包含 local 和 server 的目录"];
    
    if ([alert runModal] == NSAlertDefaultReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://code.google.com/p/goagent/"]];
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    op.title = @"请选择包含 goagent 所在的目录，这个目录包含 local 和 server 两个目录";
    op.prompt = @"选择";
    op.canChooseFiles = NO;
    op.canChooseDirectories = YES;
    if ([op runModal] == NSFileHandlingPanelOKButton) {
        [self installFromFolder:[[op URL] path]];
        
        if ([self checkIfGoAgentInstalled]) {
            [[NSAlert alertWithMessageText:@"安装 goagent 成功"
                             defaultButton:@"确定"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"如果您还未部署过 App Engine 服务端，请先进入服务端部署标签页进行部署，再到客户端设置页进行设置，最后到状态标签页启动连接。"] runModal];
            
        } else {
            [[NSAlert alertWithMessageText:@"安装 goagent 失败"
                             defaultButton:@"确定"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"您选择的目录没有包含 local 或 server 目录，或者不是正确的 goagent 解压目录，请在客户端配置标签中尝试重新安装。"] runModal];
        }
        
    } else {
        [[NSAlert alertWithMessageText:@"尚未安装 goagent"
                         defaultButton:@"确定"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"不安装 goagent 您将无法使用 goagent 的功能，您可以在客户端配置标签页重新进行安装 goagent"] runModal];
    }
}


#pragma mark -
#pragma mark 菜单事件

- (void)showMainWindow:(id)sender {
    [self.window setLevel:NSFloatingWindowLevel];
    if ([self.window canBecomeMainWindow]) {
        [self.window makeMainWindow];
    }
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeKeyWindow];
}


- (void)exitApplication:(id)sender {
    [NSApp terminate:nil];
}


- (void)showHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/ohdarling88/GoAgentX"]];
}


#pragma mark -
#pragma mark 运行状态

- (void)toggleServiceStatus:(id)sender {
    if (proxyRunner == nil) {
        proxyRunner = [GACommandRunner new];
    }
    
    GACommandRunner *runner = proxyRunner;
    
    if ([runner isTaskRunning]) {
        [runner terminateTask];
        //[self setStatusToRunning:[NSNumber numberWithBool:NO]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GoAgent:LastRunPID"];
        
    } else {
        // 关闭可能的上次运行的 goagent
        NSInteger lastRunPID = [[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:LastRunPID"];
        if (lastRunPID > 0) {
            const char *killCmd = [[NSString stringWithFormat:@"kill %ld", lastRunPID] UTF8String];
            system(killCmd);
        }
        
        // 复制一份 local 到 Application Support
        NSString *copyPath = [self copyLocalToApplicationSupport];
        
        // 生成 proxy.ini
        NSDictionary *defaults = [self defaultSettings];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *proxyini = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"proxyinitemplate" ofType:nil] 
                                                       encoding:NSUTF8StringEncoding error:NULL];
        for (NSString *key in [defaults allKeys]) {
            NSString *value = [userDefaults stringForKey:key] ?: @"";
            if ([key isEqualToString:@"GoAgent:Local:GAEProfile"]) {
                value = [[self gaeProfiles] objectAtIndex:[value intValue]];
            } else if ([key isEqualToString:@"GoAgent:Local:ConnectMode"]) {
                value = [[self connectionModes] objectAtIndex:[value intValue]];
            }
            proxyini = [proxyini stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key]
                                                           withString:value];
        }
        [proxyini writeToFile:[copyPath stringByAppendingPathComponent:@"proxy.ini"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        
        [statusLogTextView clear];
        [statusLogTextView appendString:@"正在启动...\n"];
        
        // 启动代理
        NSArray *arguments = [NSArray arrayWithObjects:@"python", @"proxy.py", nil];
        [runner runCommand:@"/usr/bin/env"
          currentDirectory:copyPath
                 arguments:arguments
                 inputText:nil
            outputTextView:statusLogTextView 
        terminationHandler:^(NSTask *theTask) {
            [self setStatusToRunning:[NSNumber numberWithBool:NO]];
        }];
        
        [statusLogTextView appendString:@"启动完成\n"];
        
        [[NSUserDefaults standardUserDefaults] setInteger:[runner processId] forKey:@"GoAgent:LastRunPID"];
        
        [self setStatusToRunning:[NSNumber numberWithBool:YES]];
    }
}


- (void)clearStatusLog:(id)sender {
    [statusLogTextView clear];
}


#pragma mark -
#pragma mark 客户端设置

- (void)applyClientSettings:(id)sender {
    [proxyRunner terminateTask];
    sleep(1);
    [self toggleServiceStatus:nil];
}


#pragma mark -
#pragma mark 服务端部署

- (void)clearDeployLog:(id)sender {
    [[deployLogTextView textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
}


- (void)deployButtonClicked:(id)sender {
    static GACommandRunner *runner = nil;
    if (runner == nil) {
        runner = [GACommandRunner new];
    }
    
    if ([runner isTaskRunning]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"部署服务端"
                                         defaultButton:@"确定"
                                       alternateButton:@"取消"
                                           otherButton:@"仅停止部署"
                             informativeTextWithFormat:@"正在部署服务端，是否取消当前的进程，重新开始进行部署？"];
        NSInteger ret = [alert runModal];
        if (ret == NSAlertAlternateReturn) {
            return;
        } else if (ret == NSAlertOtherReturn) {
            [runner terminateTask];
            return;
        }
    }
    
    
    // 复制一份 server 到 Application Support
    NSString *copyPath = [self copyServerToApplicationSupport];
    
    // 如果有服务密码，修改 fetch.py
    NSString *servicePassword = deployServicePasswordField.stringValue;
    if (servicePassword.length > 0) {
        NSString *fetchpyPath = [[copyPath stringByAppendingPathComponent:@"python"] stringByAppendingPathComponent:@"fetch.py"];
        NSString *content = [[NSString alloc] initWithContentsOfFile:fetchpyPath encoding:NSUTF8StringEncoding error:NULL];
        content = [content stringByReplacingOccurrencesOfString:@"__password__ = ''"
                                                     withString:[NSString stringWithFormat:@"__password__ = '%@'", servicePassword]
                                                        options:NSLiteralSearch
                                                          range:NSMakeRange(0, 300)];
        [content writeToFile:fetchpyPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    
    // 启动部署进程
    NSArray *arguments = [NSArray arrayWithObjects:@"uploaddir=python", @"python", @"uploader.zip", nil];
    NSArray *input = [NSArray arrayWithObjects:
                      deployAppIdField.stringValue ?: @"",
                      deployUsernameField.stringValue ?: @"",
                      deployPasswordField.stringValue ?: @"",
                      @"",
                      nil];
    [deployLogTextView clear];
    [deployLogTextView appendString:@"开始部署...\n"];
    [runner runCommand:@"/usr/bin/env"
      currentDirectory:copyPath
             arguments:arguments
             inputText:[input componentsJoinedByString:@"\n"]
        outputTextView:deployLogTextView
    terminationHandler:^(NSTask *theTask) {
        if ([theTask terminationStatus] == 0) {
            [deployLogTextView appendString:@"部署成功"];
        } else {
            [deployLogTextView appendString:@"部署失败，请查看日志并检查设置是否正确"];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:copyPath error:NULL];
    }];
}


#pragma mark -
#pragma mark 其他设置

- (CFStringRef)proxiesPathOfDevice:(NSString *)devId {
    NSString *path = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, devId, kSCEntNetProxies];
    return (__bridge CFStringRef)path;
}


//! 修改代理设置的字典
- (void)modifyPrefProxiesDictionary:(NSMutableDictionary *)proxies withProxyEnabled:(BOOL)enabled {
    if (enabled) {
        NSInteger proxyPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:Local:Port"];
        BOOL usePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:AutoToggleSystemProxyWithPAC"];
        BOOL useCustomePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:UseCustomPACAddress"];
        NSString *customPAC = [[NSUserDefaults standardUserDefaults] stringForKey:@"GoAgent:CustomPACAddress"];
        NSString *pacFile = useCustomePAC ? customPAC : @"http://127.0.0.1:8089/goagent.pac";
        
        if (usePAC) {
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
            [proxies setObject:pacFile forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
            
        } else {
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
            [proxies setObject:[NSNumber numberWithInteger:proxyPort] forKey:(NSString *)kCFNetworkProxiesHTTPPort];
            [proxies setObject:@"127.0.0.1" forKey:(NSString *)kCFNetworkProxiesHTTPProxy];
        }
        
    } else {
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
    }
}


- (void)setSystemProxySettingsToGoAgent:(BOOL)apply {
    SCPreferencesRef prefRef;// = SCPreferencesCreate(kCFAllocatorSystemDefault, CFSTR("test"), NULL);
    
    AuthorizationRef auth = nil;
	OSStatus authErr = noErr;
	
	AuthorizationFlags rootFlags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights 
    | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize;
	authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, rootFlags, &auth);
	if (authErr == noErr) {
		prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("GoAgentX"), nil, auth);
	}
    
    NSDictionary *sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
    
    // 遍历系统中的网络设备列表，设置 AirPort 和 Ethernet 的代理
    for (NSString *key in [sets allKeys]) {
        NSMutableDictionary *dict = [sets objectForKey:key];
        NSString *hardware = [dict valueForKeyPath:@"Interface.Hardware"];
        if ([hardware isEqualToString:@"AirPort"] || [hardware isEqualToString:@"Ethernet"]) {
            [previousDeviceProxies setObject:[dict mutableCopy] forKey:key];
        }
    }
    
    if (apply) {        
        // 如果已经获取了旧的代理设置就直接用之前获取的，防止第二次获取到设置过的代理
        for (NSString *deviceId in previousDeviceProxies) {
            BOOL ret;
            CFDictionaryRef proxies = SCPreferencesPathGetValue(prefRef, [self proxiesPathOfDevice:deviceId]);
            [self modifyPrefProxiesDictionary:(__bridge NSMutableDictionary *)proxies withProxyEnabled:YES];
            ret = SCPreferencesPathSetValue(prefRef, [self proxiesPathOfDevice:deviceId], proxies);
        }
        
    } else {
        for (NSString *deviceId in previousDeviceProxies) {
            // 防止之前获取的代理配置还是启用了 SOCKS 代理或者 PAC 的，直接将两种代理方式禁用
            BOOL ret;    
            NSMutableDictionary *dict = [[previousDeviceProxies objectForKey:deviceId] objectForKey:(NSString *)kSCEntNetProxies];
            [self modifyPrefProxiesDictionary:dict withProxyEnabled:NO];
            ret = SCPreferencesPathSetValue(prefRef, [self proxiesPathOfDevice:deviceId], (__bridge CFDictionaryRef)dict);
        }
        
        [previousDeviceProxies removeAllObjects];
    }
    
    SCPreferencesCommitChanges(prefRef);
    SCPreferencesApplyChanges(prefRef);
    SCPreferencesSynchronize(prefRef);
}


#pragma mark -
#pragma mark Window delegate

- (BOOL)windowShouldClose:(id)sender {
    [self.window orderOut:nil];
    return NO;
}


#pragma mark -
#pragma mark App delegate

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([proxyRunner isTaskRunning]) {
        [self toggleServiceStatus:nil];
    }
    return NSTerminateNow;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    previousDeviceProxies = [NSMutableDictionary new];
    
    // 设置状态日志最大为10K
    statusLogTextView.maxLength = 10000;
    
    // 注册默认偏好设置
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self defaultSettings]];
    
    // 设置 MenuBar 图标
    [self setupStatusItem];
    
    // 如果没有安装 goagent 就提示安装
    if (![self checkIfGoAgentInstalled]) {
        [self showInstallPanel:nil];
    }
    
    // 如果已经配置过 appid，则直接尝试连接，否则显示主窗口
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"GoAgent:Local:AppId"] length] > 0) {
        [self toggleServiceStatus:nil];
    } else {
        [self showMainWindow:nil];
    }
}


@end
