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


- (BOOL)isRunning {
    return [runner isTaskRunning];
}


- (NSString *)serviceName {
    return @"west-chamber-proxy";
}



@end
