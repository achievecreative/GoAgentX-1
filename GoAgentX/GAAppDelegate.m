//
//  GAAppDelegate.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-2-13.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAAppDelegate.h"

#import "GAConfigFieldManager.h"
#import "GAStunnelService.h"

#import "THUserNotification.h"


@implementation GAAppDelegate

@synthesize window = _window;

#pragma mark -
#pragma mark Helper

- (void)setStatusToRunning:(NSNumber *)status {
    BOOL running = [status boolValue];
    
    NSString *statusText = @"正在运行";
    if ([proxyService proxyPort] > 0) {
        statusText = [statusText stringByAppendingFormat:@"，端口 %d", [proxyService proxyPort]];
    }
    NSImage *statusImage = [NSImage imageNamed:@"status_running"];
    NSString *buttonTitle = @"停止";
    
    if (!running) {
        statusText = @"已停止";
        statusImage = [NSImage imageNamed:@"status_stopped"];
        buttonTitle = [proxyService willAutoReconnect] ? @"停止重连" : @"启动";
    }
    
    statusText = [NSString stringWithFormat:@"%@ %@", [proxyService serviceTitle], statusText];
    statusTextLabel.stringValue = statusText;
    statusImageView.image = statusImage;
    statusMenuItem.title = statusText;
    statusMenuItem.image = statusImage;
    statusBarItem.toolTip = statusMenuItem.title;
    statusBarItem.image = [NSImage imageNamed:[@"status_item_icon" stringByAppendingString:(running ? @"" : @"_stopped")]];
    statusToggleButton.title = buttonTitle;
    
    // notification center for os x 10.6+
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgentX:ServiceStateChangedNotification"]) {
        THUserNotification *notification = [THUserNotification notification];
        notification.title = @"GoAgentX";
        notification.informativeText = statusText;
        //设置通知提交的时间
        notification.deliveryDate = [NSDate dateWithTimeIntervalSinceNow:1];
        
        THUserNotificationCenter *center = [THUserNotificationCenter notificationCenter];
        if ([center isKindOfClass:[THUserNotificationCenter class]]) {
            center.centerType = THUserNotificationCenterTypeBanner;
        }
        //删除已经显示过的通知(已经存在用户的通知列表中的)
        [center removeAllDeliveredNotifications];
        //递交通知
        [center deliverNotification:notification];
        //设置通知的代理
        [center setDelegate:self];
        
        [self performSelector:@selector(removeUserNotification:) withObject:notification afterDelay:5.0];
    }
}


- (void)removeUserNotification:(NSUserNotification *)notification {
    [[THUserNotificationCenter notificationCenter] removeDeliveredNotification:notification];
}


- (void)setupStatusItem {
    statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:23.0];
    statusBarItem.image = [NSImage imageNamed:@"status_item_icon"];
    statusBarItem.alternateImage = [NSImage imageNamed:@"status_item_icon_alt"];
    statusBarItem.menu = statusBarItemMenu;
    [statusBarItem setHighlightMode:YES];
}


#pragma mark -
#pragma mark 菜单事件

- (void)showMainWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:nil];
}


- (void)exitApplication:(id)sender {
    [NSApp terminate:nil];
}


- (void)showHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/ohdarling88/GoAgentX"]];
}


- (void)showAbout:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}


#pragma mark -
#pragma mark 运行状态

- (void)refreshSystemProxySettings:(id)sender {
    [proxyService toggleSystemProxy:![[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:DontAutoToggleSystemProxySettings"]];
}


- (void)loadProxyService {
    NSInteger index = [servicesListPopButton.itemArray indexOfObject:[servicesListPopButton selectedItem]];
    if (index == NSNotFound) {
        return;
    }
    
    proxyService = [servicesList objectAtIndex:index];
}


- (void)switchRunningService:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        [servicesListPopButton selectItemWithTitle:[sender title]];
    }
    
    if ([proxyService isRunning]) {
        [proxyService stop];
        [self performSelector:@selector(toggleServiceStatus:) withObject:nil afterDelay:1.0];
    } else {
        [self loadProxyService];
        [self setStatusToRunning:[NSNumber numberWithBool:NO]];
    }
}


- (void)selectedServiceChanged:(id)sender {
}


- (void)toggleServiceStatus:(id)sender {
    if ([proxyService isRunning]) {
        [proxyService stop];
        
    } else if ([proxyService willAutoReconnect]) {
        [proxyService stop];
        statusToggleButton.title = @"启动";
        [statusLogTextView appendString:@"\n已停止"];
    
    } else {
        [self loadProxyService];
        NSLog(@"Starting %@ ...", [proxyService serviceTitle]);
        [proxyService start];
        pacServerAddressField.stringValue = [[GAPACHTTPServer sharedServer] pacAddressForProxy:[proxyService proxySetting]];
        [[NSUserDefaults standardUserDefaults] setObject:[proxyService serviceTitle] forKey:@"GoAgentX:SelectedService"];
    }
}


- (void)clearStatusLog:(id)sender {
    [statusLogTextView clear];
}


#pragma mark -
#pragma mark TextView delegate

- (void)stunnelServerListDidChange:(NSNotification *)notification {
    NSTextView *textView = stunnelServerListTextView;
    NSString *text = textView.string;
    
    [GAStunnelService loadServices:[GAStunnelService parseServicesList:text]
                      toPopupButton:stunnelSelectedServerPopupButton];
}


#pragma mark -
#pragma mark Window delegate

- (BOOL)windowShouldClose:(id)sender {
    [self.window orderOut:nil];
    return NO;
}


#pragma mark -
#pragma mark App delegate

- (void)loadServicesList {
    servicesList = [NSMutableArray new];
    
    NSArray *classList = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GoAgentXServices" ofType:@"plist"]];
    
    [servicesListPopButton removeAllItems];
    for (NSString *clsName in classList) {
        Class cls = NSClassFromString(clsName);
        if (cls != nil) {
            GAService *service = [cls sharedService];
            [servicesList addObject:service];
            
            __block id _self = self;
            service.outputTextView = statusLogTextView;
            service.statusChangedHandler = ^(GAService *service) {
                [_self setStatusToRunning:[NSNumber numberWithBool:[service isRunning]]];
            };
            
            [servicesListPopButton addItemWithTitle:[service serviceTitle]];
            
            if ([service canShowInSwitchMenu]) {
                [servicesListMenu addItemWithTitle:[service serviceTitle] action:@selector(switchRunningService:) keyEquivalent:@""];
            }
        }
    }
    
    [servicesListPopButton selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"GoAgentX:SelectedService"]];
}


- (void)setupStunnelPrefs {
    // 监听 Stunnel 服务器列表改变事件
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stunnelServerListDidChange:)
                                                 name:NSTextDidChangeNotification 
                                               object:stunnelServerListTextView];
    [self stunnelServerListDidChange:nil];
}


- (void)setupPACServer {
    int newPort = 0;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgentX:UseCustomPACServerPort"]) {
        // 自定义 PAC 端口
        UInt16 pacServerPort = (UInt16)[[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgentX:CustomPACServerPort"];
        newPort = pacServerPort;
    }
    
    pacServer = [GAPACHTTPServer sharedServer];
    if (newPort != [pacServer port]) {
        [pacServer setPort:newPort];
        
        if ([pacServer isRunning]) {
            [pacServer stop];
        }
    }
    
    if (![pacServer isRunning]) {
        [pacServer start:NULL];
    }
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([proxyService isRunning]) {
        [proxyService stop];
        [proxyService notifyStatusChanged];
    }
    
    return NSTerminateNow;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 初始化服务列表
    [self loadServicesList];
    
    [[GAConfigFieldManager sharedManager] setupWithTabView:servicesConfigTabView];
    
    // 启动本机 PAC 服务
    [self setupPACServer];
    
    // 设置状态日志最大为10K
    statusLogTextView.maxLength = 10000;
    
    // 注册默认偏好设置
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithContentsOfFile:
      [[NSBundle mainBundle] pathForResource:@"GoAgentXDefaultsSettings" ofType:@"plist"]]];
    
    // 初始化 stunnel 设置
    [self setupStunnelPrefs];
    
    // 设置 MenuBar 图标
    [self setupStatusItem];
    
    // 尝试启动服务
    if ([proxyService couldAutoStart]) {
        [self toggleServiceStatus:nil];
    }
    
    // 如果没有配置，则显示主窗口
    if (![proxyService hasConfigured]) {
        [self showMainWindow:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
}


#pragma mark -
#pragma mark Other delegate

- (void)showStunnelConfigurationExample:(id)sender {
    NSString *content = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"stunnel-config-example" ofType:@""]
                                                        encoding:NSUTF8StringEncoding
                                                           error:NULL];
    NSAlert *alert = [NSAlert alertWithMessageText:@"Stunnel 服务器列表示例"
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", content ?: @""];
    [alert runModal];
}


- (void)setAutoToggleProxySettingType:(id)sender {
    NSMutableArray *types = [NSMutableArray new];
    
    if ([sender isKindOfClass:[NSButton class]]) {
        for (NSButton *button in [(NSButton *)sender superview].subviews) {
            if ([button isKindOfClass:[NSButton class]] && [button.identifier hasPrefix:@"AutoToggleProxySettingType"]) {
                [types addObject:button];
            }
        }
    } else if ([sender isKindOfClass:[NSMenuItem class]]) {
        for (NSMenuItem *item in [(NSMenuItem *)sender menu].itemArray) {
            if (item != sender) {
                [types addObject:item];
            }
        }
    }
    
    for (NSButton *button in types) {
        [button setState:(button == sender ? NSOnState : NSOffState)];
        NSString *key = [[[button infoForBinding:@"value"] objectForKey:NSObservedKeyPathKey] substringFromIndex:7];
        [[NSUserDefaults standardUserDefaults] setInteger:[button state] forKey:key];
    }
    
    if ([proxyService isRunning]) {
        [self performSelector:@selector(refreshSystemProxySettings:) withObject:nil afterDelay:0.1];
    }
}


- (void)applyCustomPACCustomDomainList:(id)sender {
    if ([proxyService isRunning] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:DontAutoToggleSystemProxySettings"]) {
        [proxyService toggleSystemProxy:NO];
        [self performSelector:@selector(refreshSystemProxySettings:) withObject:nil afterDelay:0.1];
    }
}


- (void)importGoagentCA:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"CA" ofType:@"crt" inDirectory:@"goagent"]];
}


- (void)userDefaultsChanged:(NSNotification *)note {
    BOOL mainWindowAlwaysOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgentX:MainWindowAlwaysOnTop"];
    [self.window setLevel:mainWindowAlwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
}


- (void)selectLocalPacFileButtonClicked:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"pac"];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSString *path = panel.URL.absoluteString;
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"GoAgent:CustomPACAddress"];
        }
    }];
}


#pragma mark - THUserNotificationCenter delegate

- (void)userNotificationCenter:(THUserNotificationCenter *)center didActivateNotification:(THUserNotification *)notification {
//    [self showMainWindow:nil];
}


- (void)userNotificationCenter:(THUserNotificationCenter *)center didDeliverNotification:(THUserNotification *)notification {
    // do nothing
}


- (BOOL)userNotificationCenter:(THUserNotificationCenter *)center shouldPresentNotification:(THUserNotification *)notification {
    return NO;
}


@end
