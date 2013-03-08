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
    if (addDomain != nil && [pacList indexOfObject:addDomain] == NSNotFound) {
        [pacList addObject:addDomain];
    }
    
    NSString *removeDomain = [[self evaluatedArguments] objectForKey:@"RemoveDomain"];
    if (removeDomain != nil && [pacList indexOfObject:removeDomain] != NSNotFound) {
        [pacList removeObject:removeDomain];
    }
    
    [pacStr.mutableString setString:[pacList componentsJoinedByString:@"\n"]];
    pacData = [NSArchiver archivedDataWithRootObject:pacStr];
    [[NSUserDefaults standardUserDefaults] setObject:pacData forKey:pacDataKey];
    
    GAAppDelegate *appDelegate = [NSApp delegate];
    [appDelegate applyCustomPACCustomDomainList:nil];
    
    return nil;
}


@end
