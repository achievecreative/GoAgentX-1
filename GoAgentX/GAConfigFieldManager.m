//
//  GAConfigFieldManager.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAConfigFieldManager.h"

#import "SynthesizeSingleton.h"

@implementation GAConfigFieldManager

SYNTHESIZE_SINGLETON_FOR_CLASS(GAConfigFieldManager, Manager)

- (void)setupWithTabView:(NSTabView *)tabView {
    fieldsControlMap = [NSMutableDictionary new];
    
    for (NSTabViewItem *item in tabView.tabViewItems) {
        NSString *service = [item identifier];
        for (NSControl *control in [(NSView *)item.view subviews]) {
            NSString *identifier = [control respondsToSelector:@selector(identifier)] ? [control identifier] : nil;
            
            if (identifier != nil && 
                ([control isKindOfClass:[NSSegmentedControl class]] ||
                 [control isKindOfClass:[NSButton class]] || 
                 [control isKindOfClass:[NSTextField class]])) {
                    [fieldsControlMap setObject:control
                                         forKey:[NSString stringWithFormat:@"%@:%@", service, identifier]];
                }
        }
    }
}


- (NSString *)configValueForKey:(NSString *)key ofService:(NSString *)service {
    NSControl *control = [fieldsControlMap objectForKey:[NSString stringWithFormat:@"%@:%@", service, key]];
    NSString *ret = @"";
    if ([control isKindOfClass:[NSButton class]]) {
        ret = [(NSButton *)control state] == NSOnState ? @"1" : @"0";
        
    } else if ([control isKindOfClass:[NSTextField class]]) {
        ret = [(NSTextField *)control stringValue] ?: @"";
        
    } else if ([control isKindOfClass:[NSSegmentedControl class]]) {
        ret = [NSString stringWithFormat:@"%ld", [(NSSegmentedControl *)control selectedSegment]];
    }
    
    return ret ?: @"";
}

@end
