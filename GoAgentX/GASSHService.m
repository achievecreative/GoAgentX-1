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


- (NSString *)configPath {
    return nil;
}


- (BOOL)supportReconnectAfterDisconnected {
    return YES;
}


- (BOOL)autoDisconnectWhenNetworkIsUnreachable {
    return YES;
}


- (BOOL)hasConfigured {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:@"SSH:RemoteServer"].length > 0;
}


- (int)proxyPort {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"SSH:LocalPort"];
}

- (bool)listenOnRemote {
    return (bool)[[NSUserDefaults standardUserDefaults] boolForKey:@"SSH:ListenOnRemote"];
}


- (NSArray *)proxyTypes {
    return @[@"SOCKS5", @"SOCKS"];
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
    [args addObject:[NSString stringWithFormat:@"%s:%d", [self listenOnRemote] ? "*" : "localhost", [self proxyPort]]];
    if ([defaults stringForKey:@"SSH:ObfuscateKeyword"].length > 0) {
        commandRunner.commandPath = @"./obfuscated-ssh";
        [args addObject:@"-zZ"];
        [args addObject:[defaults stringForKey:@"SSH:ObfuscateKeyword"]];
    }
    
    NSString *identityFile = [defaults stringForKey:@"SSH:IdentityFile"];
    if ([identityFile length] > 0) {
      [args addObject:@"-i"];
      [args addObject:identityFile];
    }
    
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
