//
//  GAAppDelegate.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-2-13.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAAppDelegate.h"

#import "GAConfigFieldManager.h"


@implementation GAAppDelegate

@synthesize window = _window;

#pragma mark -
#pragma mark Helper

- (void)setStatusToRunning:(NSNumber *)status {
    BOOL running = [status boolValue];
    
    NSString *statusText = @"正在运行";
    if ([proxyService proxyPort] > 0) {
        statusText = [statusText stringByAppendingFormat:@"，端口 %ld", [proxyService proxyPort]];
    }
    NSImage *statusImage = [NSImage imageNamed:@"status_running"];
    NSString *buttonTitle = @"停止";
    
    if (!running) {
        statusText = @"已停止";
        statusImage = [NSImage imageNamed:@"status_stopped"];
        buttonTitle = @"启动";
    }
    
    statusBarItem.toolTip = statusText;
    statusTextLabel.stringValue = statusText;
    statusImageView.image = statusImage;
    statusMenuItem.title = statusText;
    statusMenuItem.image = statusImage;
    statusToggleButton.title = buttonTitle;
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

- (void)toggleServiceStatus:(id)sender {
    if ([proxyService isRunning]) {
        [proxyService stop];
        
    } else {
        NSInteger index = [servicesListPopButton.itemArray indexOfObject:[servicesListPopButton selectedItem]];
        if (index == NSNotFound) {
            return;
        }
        
        NSString *className = [[servicesList objectAtIndex:index] objectForKey:@"ClassName"];
        Class serviceCls = NSClassFromString(className);
        
        proxyService = [serviceCls sharedService];
        __block id _self = self;
        proxyService.outputTextView = statusLogTextView;
        proxyService.statusChangedHandler = ^(GAService *service) {
            [_self setStatusToRunning:[NSNumber numberWithBool:[service isRunning]]];
        };
        
        [proxyService start];
    }
}


- (void)clearStatusLog:(id)sender {
    [statusLogTextView clear];
}


#pragma mark -
#pragma mark Window delegate

- (BOOL)windowShouldClose:(id)sender {
    [self.window orderOut:nil];
    return NO;
}


#pragma mark -
#pragma mark App delegate

- (void)setupServicesList {
    servicesList = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GoAgentXServices" ofType:@"plist"]];
    
    [servicesListPopButton removeAllItems];
    for (NSDictionary *service in servicesList) {
        [servicesListPopButton addItemWithTitle:[service objectForKey:@"Title"]];
    }
    
    [servicesListPopButton selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"GoAgentX:SelectedService"]];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [proxyService stop];
    
    return NSTerminateNow;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupServicesList];
    
    [[GAConfigFieldManager sharedManager] setupWithTabView:servicesConfigTabView];
    
    // 设置状态日志最大为10K
    statusLogTextView.maxLength = 10000;
    
    // 注册默认偏好设置
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithContentsOfFile:
      [[NSBundle mainBundle] pathForResource:@"GoAgentXDefaultsSettings" ofType:@"plist"]]];
    
    // 设置 MenuBar 图标
    [self setupStatusItem];
    
    // 尝试启动服务
    [self toggleServiceStatus:nil];
    
    // 如果没有配置，则显示主窗口
    if (![proxyService hasConfigured]) {
        [self showMainWindow:nil];
    }
}


@end
