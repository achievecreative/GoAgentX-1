//
//  GASSHService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-5-5.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GASSHService.h"

@implementation GASSHService

- (NSString *)serviceName {
    return @"ssh";
}


- (NSString *)serviceTitle {
    return @"SSH";
}


- (BOOL)supportReconnectAfterDisconnected {
    BOOL ret = [[NSUserDefaults standardUserDefaults] boolForKey:@"SSH:AutoReconnect"];
    return ret;
}


- (NSString *)configPath {
    return nil;
}


- (BOOL)hasConfigured {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:@"SSH:RemoteServer"].length > 0;
}


- (int)proxyPort {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"SSH:LocalPort"];
}


- (NSString *)proxySetting {
    return [NSString stringWithFormat:@"SOCKS 127.0.0.1:%d", [self proxyPort]];
}


- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"ssh";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *args = [NSMutableArray new];
    [args addObject:@"-N"];     // Do not execute a remote command
    [args addObject:[NSString stringWithFormat:@"%@@%@", 
                     [defaults stringForKey:@"SSH:RemoteUsername"],
                     [defaults stringForKey:@"SSH:RemoteServer"]]];
    [args addObject:@"-p"];
    [args addObject:[defaults stringForKey:@"SSH:RemotePort"]];
    [args addObject:@"-D"];
    [args addObject:[NSString stringWithFormat:@"127.0.0.1:%d", [self proxyPort]]];
    
    // Borrowed from iSSH
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
    [env removeObjectForKey:@"SSH_AGENT_PID"];
    [env removeObjectForKey:@"SSH_AUTH_SOCK"];
    [env setObject:@":0" forKey:@"DISPLAY" ];
    [env setObject:[[self serviceWorkDirectory] stringByAppendingPathComponent:@"echo.sh"] forKey:@"SSH_ASKPASS"];
    [env setObject:[defaults stringForKey:@"SSH:RemotePassword"] ?: @"" forKey:@"ECHO_CONTENT"];
    commandRunner.environment = env;
    
    commandRunner.arguments = args;
}


@end
