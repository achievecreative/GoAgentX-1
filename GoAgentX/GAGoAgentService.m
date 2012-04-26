//
//  GAGoAgentService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-24.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAGoAgentService.h"

@implementation GAGoAgentService

- (BOOL)hasConfigured {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"GoAgent:Local:AppId"] length] > 0;
}


- (NSString *)configTemplate {
    return [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"goagent-config-template" ofType:@""]
                                           encoding:NSUTF8StringEncoding
                                              error:NULL];
}


- (NSString *)configPath {
    return @"proxy.ini";
}


- (NSString *)serviceName {
    return @"goagent";
}


- (int)proxyPort {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:Local:Port"];
}


- (NSString *)proxySetting {
    return [NSString stringWithFormat:@"PROXY 127.0.0.1:%d", [self proxyPort]];
}


- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"/usr/bin/env";
    commandRunner.arguments = [NSArray arrayWithObjects:@"python", @"proxy.py", nil];
    commandRunner.inputText = nil;
}

@end
