//
//  GAGoAgentUpdateService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 13-4-13.
//  Copyright (c) 2013年 xujiwei.com. All rights reserved.
//

#import "GAGoAgentUpdateService.h"

@implementation GAGoAgentUpdateService

- (NSString *)serviceName {
    return @"goagent-update";
}


- (NSString *)serviceTitle {
    return NSLocalizedString(@"goagent 更新", nil);
}


- (BOOL)hasConfigured {
    return YES;
}


- (NSString *)configTemplate {
    return nil;
}


- (NSString *)configPath {
    return nil;
}


- (BOOL)canShowInSwitchMenu {
    return NO;
}


- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"bash";
    commandRunner.arguments = @[ @"./update_goagent.sh" ];
    commandRunner.environment = @{ @"APP_BUNDLE_PATH": [[NSBundle mainBundle] bundlePath] };
}


@end
