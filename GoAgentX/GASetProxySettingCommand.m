//
//  GASetProxySettingCommand.m
//  GoAgentX
//
//  Created by Xu Jiwei on 13-3-7.
//  Copyright (c) 2013年 xujiwei.com. All rights reserved.
//

#import "GASetProxySettingCommand.h"

#import "GAAppDelegate.h"
#import "GAService.h"

@implementation GASetProxySettingCommand


typedef NS_ENUM(NSUInteger, GAProxySetting) {
    GAProxySettingDontToggle        = 'nchg',
    GAProxySettingToggleSystemProxy = 'glob',
    GAProxySettingToggleWithPAC     = 'upac',
};


- (id)performDefaultImplementation {
    NSArray *keys = @[@"GoAgent:DontAutoToggleSystemProxySettings",
                      @"GoAgent:AutoToggleSystemProxySettings",
                      @"GoAgent:AutoToggleSystemProxyWithPAC"];
    NSUInteger indexes[3] = { GAProxySettingDontToggle, GAProxySettingToggleSystemProxy, GAProxySettingToggleWithPAC };
    
    for (NSString *key in keys) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:key];
    }
    
    GAProxySetting selectedSetting = [[[self evaluatedArguments] objectForKey:@"ProxySetting"] unsignedIntegerValue];
    for (int i = 0; i < 3; ++i) {
        if (indexes[i] == selectedSetting) {
            NSString *key = [keys objectAtIndex:i];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
        }
    }
    
    GAAppDelegate *appDelegate = [NSApp delegate];
    if ([appDelegate.currentService isRunning]) {
        [appDelegate performSelector:@selector(refreshSystemProxySettings:) withObject:nil afterDelay:0.1];
    }
    
    return nil;
}

@end
