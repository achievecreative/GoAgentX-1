//
//  GAConfigFieldManager.h
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GAConfigFieldManager : NSObject {
    NSMutableDictionary     *fieldsControlMap;
}

+ (id)sharedManager;

- (void)setupWithTabView:(NSTabView *)tabView;

- (NSString *)configValueForKey:(NSString *)key ofService:(NSString *)service;

@end
