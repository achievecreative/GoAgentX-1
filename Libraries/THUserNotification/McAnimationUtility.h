//
//  McAnimationUtility.h
//  RestAnimation
//
//  Created by tanhao on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface McAnimationUtility : NSObject
+ (void)setAnchorPoint:(CGPoint)anchorPoint forView:(NSView *)view;
@end


@interface NSImage (stretchable)
- (NSImage *)drawStretchableInRect:(NSRect)rect edgeInsets:(NSEdgeInsets)insets;
+ (NSImage *)image:(NSImage *)image leftCapWidth:(float)leftWidth middleWidth:(float)middleWidth rightCapWidth:(float)rightWidth;
@end