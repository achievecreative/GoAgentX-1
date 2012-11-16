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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *server = [defaults stringForKey:@"ShadowSocks:Server"] ?: @"";
    NSString *remotePort = [defaults stringForKey:@"ShadowSocks:ListenOnRemote"] ?: @"";
    NSString *localPort = [defaults stringForKey:@"ShadowSocks:LocalPort"] ?: @"";
    NSString *pass = [defaults stringForKey:@"ShadowSocks:Password"] ?: @"";
    NSString *timeout = [defaults stringForKey:@"ShadowSocks:Timeout"] ?: @"";
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{ShadowSocks:Server}" withString:server];
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{ShadowSocks:ListenOnRemote}" withString:remotePort];
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{ShadowSocks:LocalPort}" withString:localPort];
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{ShadowSocks:Password}" withString:pass];
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{ShadowSocks:Timeout}" withString:timeout];
    
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

- (NSString *)proxySetting {
    return [NSString stringWithFormat:@"SOCKS 127.0.0.1:%d; SOCKS5 127.0.0.1:%d", [self proxyPort], [self proxyPort]];
}

- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"/usr/bin/env";
    commandRunner.arguments = [NSArray arrayWithObjects:@"python", @"local.py", nil];
    commandRunner.inputText = nil;
}

@end
