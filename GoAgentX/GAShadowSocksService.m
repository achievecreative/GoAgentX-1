//
//  GAShadowSocksService.m
//  GoAgentX
//
//  Created by messense on 12-11-16.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAShadowSocksService.h"

@implementation GAShadowSocksService

- (BOOL)hasConfigured {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"ShadowSocks:Server"] length] > 0;
}

- (NSString *)configTemplate {
    NSString *tpl = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shadowsocks-config-template" ofType:@""]
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
    return tpl;
}


- (NSString *)configPath {
    return @"config.json";
}

- (NSString *)serviceName {
    return @"shadowsocks";
}

- (NSString *)serviceTitle {
    return @"shadowsocks";
}


- (BOOL)supportReconnectAfterDisconnected {
    return YES;
}

- (int)proxyPort {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"ShadowSocks:LocalPort"];
}

- (bool)listenOnRemote {
    return (bool)[[NSUserDefaults standardUserDefaults] boolForKey:@"ShadowSocks:ListenOnRemote"];
}

- (NSArray *)proxyTypes {
    return @[@"SOCKS5", @"SOCKS"];
}

- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"./ss-local";
    commandRunner.arguments = [NSArray arrayWithObjects:@"-c", @"config.json", nil];

    commandRunner.inputText = nil;
}

@end
