//
//  GAModifyPACListCommand.m
//  GoAgentX
//
//  Created by Xu Jiwei on 13-3-8.
//  Copyright (c) 2013年 xujiwei.com. All rights reserved.
//

#import "GAModifyPACListCommand.h"

#import "GAAppDelegate.h"

@implementation GAModifyPACListCommand


- (id)performDefaultImplementation {
    NSString *pacDataKey = @"GoAgentX:CustomPACDomainList";
    
    NSData *pacData = [[NSUserDefaults standardUserDefaults] dataForKey:pacDataKey];
    id attributedStr = [NSUnarchiver unarchiveObjectWithData:pacData];
    NSMutableAttributedString *pacStr = [attributedStr mutableCopy];
    NSMutableArray *pacList = [[pacStr.string componentsSeparatedByString:@"\n"] mutableCopy];
    
    NSString *addDomain = [[self evaluatedArguments] objectForKey:@"AddDomain"];
    for (NSString *domain in [addDomain componentsSeparatedByString:@"\n"]) {
        if (domain.length > 0 && [pacList indexOfObject:domain] == NSNotFound) {
            [pacList addObject:domain];
        }
    }
    
    NSString *removeDomain = [[self evaluatedArguments] objectForKey:@"RemoveDomain"];
    for (NSString *domain in [removeDomain componentsSeparatedByString:@"\n"]) {
        if (domain.length > 0 && [pacList indexOfObject:domain] != NSNotFound) {
            [pacList removeObject:domain];
        }
    }
    
    [pacStr.mutableString setString:[pacList componentsJoinedByString:@"\n"]];
    pacData = [NSArchiver archivedDataWithRootObject:pacStr];
    [[NSUserDefaults standardUserDefaults] setObject:pacData forKey:pacDataKey];
    
    GAAppDelegate *appDelegate = [NSApp delegate];
    [appDelegate applyCustomPACCustomDomainList:nil];
    
    return nil;
}


@end
