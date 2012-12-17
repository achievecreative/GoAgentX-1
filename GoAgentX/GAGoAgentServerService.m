//
//  GAGoAgentServerService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAGoAgentServerService.h"

@implementation GAGoAgentServerService

- (BOOL)couldAutoStart {
    return NO;
}


- (BOOL)hasConfigured {
    return [self configValueForKey:@"appid"].length > 0 && [self configValueForKey:@"username"].length > 0 && [self configValueForKey:@"password"].length > 0;
}


- (BOOL)canShowInSwitchMenu {
    return NO;
}


- (NSString *)serviceName {
    return @"goagent-server";
}


- (NSString *)serviceTitle {
    return @"goagent 服务端部署";
}


- (NSString *)configPath {
    return nil;
}


- (void)setupWorkDirectory {
    [super setupWorkDirectory];
    
    // 如果有服务密码，修改 fetch.py
    NSString *servicePassword = [self configValueForKey:@"service_password"];
    
    if (servicePassword.length > 0) {
        NSString *fetchpyPath = [[self serviceWorkDirectory] stringByAppendingPathComponent:@"fetch.py"];
        NSString *content = [[NSString alloc] initWithContentsOfFile:fetchpyPath encoding:NSUTF8StringEncoding error:NULL];
        content = [content stringByReplacingOccurrencesOfString:@"__password__ = ''"
                                                     withString:[NSString stringWithFormat:@"__password__ = '%@'", servicePassword]
                                                        options:NSLiteralSearch
                                                          range:NSMakeRange(0, 300)];
        [content writeToFile:fetchpyPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    
}


- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"/usr/bin/env";
    NSString *serverType = [[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:Server:LanguageType"] == 0 ? @"python" : @"golang";
    commandRunner.arguments = [NSArray arrayWithObjects:[@"uploaddir=" stringByAppendingString:serverType], @"python", @"uploader.zip", nil];
    NSArray *input = [NSArray arrayWithObjects:
                      [self configValueForKey:@"appid"],
                      [self configValueForKey:@"username"],
                      [self configValueForKey:@"password"],
                      @"",
                      nil];
    commandRunner.inputText = [input componentsJoinedByString:@"\n"];
    
    __block GAGoAgentServerService *_self = self;
    commandRunner.terminationHandler = ^(NSTask *theTask) {
        
        if ([theTask terminationStatus] == 0) {
            [_self.outputTextView appendString:@"部署成功\n"];
        } else {
            [_self.outputTextView appendString:@"部署失败，请查看日志并检查设置是否正确\n"];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:[_self serviceWorkDirectory] error:NULL];
        
        [_self notifyStatusChanged];
    };
}


@end
