//
//  GAShowMainWindowCommand.m
//  GoAgentX
//
//  Created by Xu Jiwei on 13-3-8.
//  Copyright (c) 2013年 xujiwei.com. All rights reserved.
//

#import "GAShowMainWindowCommand.h"

#import "GAAppDelegate.h"


typedef NS_ENUM(NSUInteger, GAMainWindowTab) {
    GAMainWindowTabStatus           = 'stus',
    GAMainWindowTabServices         = 'srvs',
    GAMainWindowTabProxySettings    = 'pxst',
    GAMainWindowTabOtherSettings    = 'otst',
};


@implementation GAShowMainWindowCommand


- (id)performDefaultImplementation {
    GAAppDelegate *appDelegate = [NSApp delegate];
    
    int indexes[4] = { GAMainWindowTabStatus, GAMainWindowTabServices, GAMainWindowTabProxySettings, GAMainWindowTabOtherSettings };
    NSArray *identifiers = @[@"status", @"services", @"proxysettings", @"othersettings"];
    
    if ([[self evaluatedArguments] objectForKey:@"ActiveTab"] != nil) {
        GAMainWindowTab tab = [[[self evaluatedArguments] objectForKey:@"ActiveTab"] unsignedIntegerValue];
        for (int i = 0; i < 4; ++i) {
            if (indexes[i] == tab) {
                NSString *identifier = identifiers[i];
                [appDelegate.mainTabView selectTabViewItemWithIdentifier:identifier];
            }
        }
    }
    
    [appDelegate showMainWindow:nil];
    
    return nil;
}


@end
