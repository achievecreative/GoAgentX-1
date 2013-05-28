//
//  GAWestChamberService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-24.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAWestChamberService.h"

@implementation GAWestChamberService

- (BOOL)hasConfigured {
    return YES;
}


- (NSString *)configTemplate {
    return [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"west-chamber-config-template" ofType:@""]
                                           encoding:NSUTF8StringEncoding
                                              error:NULL];
}


- (NSString *)configPath {
    return @"config.py";
}


- (NSString *)serviceName {
    return @"west-chamber-proxy";
}


- (NSString *)serviceTitle {
    return NSLocalizedString(@"西厢第3季", nil);
}


- (int)proxyPort {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"WestChamber:LocalPort"];
}


- (NSArray *)proxyTypes {
    return @[@"PROXY"];
}


- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"/usr/bin/env";
    commandRunner.arguments = [NSArray arrayWithObjects:@"python", @"westchamberproxy.py", nil];
}


@end
