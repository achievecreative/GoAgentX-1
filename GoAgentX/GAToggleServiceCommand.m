//
//  GAToggleServiceCommand.m
//  GoAgentX
//
//  Created by Xu Jiwei on 13-3-7.
//  Copyright (c) 2013年 xujiwei.com. All rights reserved.
//

#import "GAToggleServiceCommand.h"

#import "GAAppDelegate.h"

@implementation GAToggleServiceCommand


- (id)performDefaultImplementation {
    NSString *serviceTitle = [[self evaluatedArguments] objectForKey:@"ServiceTitle"];
    
    if (serviceTitle != nil) {
        GAAppDelegate *appDelegate = [NSApp delegate];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:serviceTitle action:NULL keyEquivalent:@""];
        [appDelegate switchRunningService:menuItem];
    }
    
    return nil;
}


@end
