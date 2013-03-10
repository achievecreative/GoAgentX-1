//
//  GAToggleServiceStatusCommand.m
//  GoAgentX
//
//  Created by Xu Jiwei on 13-3-7.
//  Copyright (c) 2013年 xujiwei.com. All rights reserved.
//

#import "GAToggleServiceStatusCommand.h"

#import "GAAppDelegate.h"
#import "GASSHService.h"


typedef NS_ENUM(NSUInteger, GAServiceStatus) {
    GAServiceStatusUnkown = 0,
    GAServiceStatusRunning = 'runn',
    GAServiceStatusStopped = 'stop'
};


@implementation GAToggleServiceStatusCommand

- (id)performDefaultImplementation {
    GAAppDelegate *appDelegate = [NSApp delegate];
    GAService *currentService = [appDelegate currentService];
    NSDictionary *args = [self evaluatedArguments];
    
    GAServiceStatus status = [[args objectForKey:@"Status"] intValue];
    if (status == GAServiceStatusUnkown) {
        [appDelegate toggleServiceStatus:nil];
        
    } else if (status == GAServiceStatusRunning) {
        if (![currentService isRunning]) {
            [appDelegate toggleServiceStatus:nil];
        }
        
    } else if (status == GAServiceStatusStopped) {
        if ([currentService isRunning] || [currentService willAutoReconnect]) {
            [appDelegate toggleServiceStatus:nil];
        }
    }
    
    return nil;
}

@end
