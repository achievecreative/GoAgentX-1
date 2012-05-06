//
//  GAStunnelService.h
//  GoAgentX
//
//  Created by Xu Jiwei on 12-5-6.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAService.h"

@interface GAStunnelService : GAService

+ (NSArray *)parseServicesList:(NSString *)text;
+ (void)loadServices:(NSArray *)services toPopupButton:(NSPopUpButton *)popupButton;

@end
