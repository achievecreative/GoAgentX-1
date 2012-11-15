//
//  McAnimationUtility.m
//  RestAnimation
//
//  Created by tanhao on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "McAnimationUtility.h"

@implementation McAnimationUtility

+ (void)setAnchorPoint:(CGPoint)anchorPoint forView:(NSView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

@end


@implementation NSImage (stretchable)

- (NSImage *)drawStretchableInRect:(NSRect)rect edgeInsets:(NSEdgeInsets)insets
{
    void (^makeAreas)(NSRect, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *) = ^(NSRect srcRect, NSRect *tl, NSRect *tc, NSRect *tr, NSRect *ml, NSRect *mc, NSRect *mr, NSRect *bl, NSRect *bc, NSRect *br) {
        CGFloat w = NSWidth(srcRect);
        CGFloat h = NSHeight(srcRect);
        CGFloat cw = w - insets.left - insets.right;
        CGFloat ch = h - insets.top - insets.bottom;
        
        CGFloat x0 = NSMinX(srcRect);
        CGFloat x1 = x0 + insets.left;
        CGFloat x2 = NSMaxX(srcRect) - insets.right;
        
        CGFloat y0 = NSMinY(srcRect);
        CGFloat y1 = y0 + insets.bottom;
        CGFloat y2 = NSMaxY(srcRect) - insets.top;
        
        *tl = NSMakeRect(x0, y2, insets.left, insets.top);
        *tc = NSMakeRect(x1, y2, cw, insets.top);
        *tr = NSMakeRect(x2, y2, insets.right, insets.top);
        
        *ml = NSMakeRect(x0, y1, insets.left, ch);
        *mc = NSMakeRect(x1, y1, cw, ch);
        *mr = NSMakeRect(x2, y1, insets.right, ch);
        
        *bl = NSMakeRect(x0, y0, insets.left, insets.bottom);
        *bc = NSMakeRect(x1, y0, cw, insets.bottom);
        *br = NSMakeRect(x2, y0, insets.right, insets.bottom);
    };
    
    // Source rects
    NSRect srcRect = (NSRect){NSZeroPoint, self.size};
    NSRect srcTopL, srcTopC, srcTopR, srcMidL, srcMidC, srcMidR, srcBotL, srcBotC, srcBotR;
    makeAreas(srcRect, &srcTopL, &srcTopC, &srcTopR, &srcMidL, &srcMidC, &srcMidR, &srcBotL, &srcBotC, &srcBotR);
    
    // Destinations rects
    NSRect dstTopL, dstTopC, dstTopR, dstMidL, dstMidC, dstMidR, dstBotL, dstBotC, dstBotR;
    makeAreas(rect, &dstTopL, &dstTopC, &dstTopR, &dstMidL, &dstMidC, &dstMidR, &dstBotL, &dstBotC, &dstBotR);
    
    NSRect srcRects[] = {srcTopL, srcTopC, srcTopR, srcMidL, srcMidC, srcMidR, srcBotL, srcBotC, srcBotR};
    NSRect dstRects[] = {dstTopL, dstTopC, dstTopR, dstMidL, dstMidC, dstMidR, dstBotL, dstBotC, dstBotR};
    NSMutableArray *partImgs = [NSMutableArray arrayWithCapacity:9];
    for (int i=0;i<9;i++)
    {
        NSRect aSrcRect = srcRects[i];
        NSRect aDstRect = dstRects[i];
        //NSImage *partImg = [[NSImage alloc] initWithSize:aDstRect.size];
        //[partImg lockFocus];
        //[self drawInRect:(NSRect){NSZeroPoint, aDstRect.size} fromRect:aSrcRect operation:NSCompositeCopy fraction:1.0];
        
        NSImage *partImg = [[NSImage alloc] initWithSize:aSrcRect.size];
        [partImg lockFocus];
        [self drawAtPoint:NSZeroPoint fromRect:aSrcRect operation:NSCompositeCopy fraction:1.0];
        [partImg setSize:aDstRect.size];
        [partImg unlockFocus];
        [partImgs addObject:partImg];
    }
    
    NSImage *resultImg = [[NSImage alloc] initWithSize:rect.size];
    [resultImg lockFocus];
    // Draw
    NSDrawNinePartImage(rect,
                        [partImgs objectAtIndex:0],
                        [partImgs objectAtIndex:1],
                        [partImgs objectAtIndex:2],
                        [partImgs objectAtIndex:3],
                        [partImgs objectAtIndex:4],
                        [partImgs objectAtIndex:5],
                        [partImgs objectAtIndex:6],
                        [partImgs objectAtIndex:7],
                        [partImgs objectAtIndex:8],
                        NSCompositeSourceOver, 1, NO);
    
    //    [self drawInRect:dstTopL fromRect:srcTopL operation:op fraction:delta];
    //    [self drawInRect:dstTopC fromRect:srcTopC operation:op fraction:delta];
    //    [self drawInRect:dstTopR fromRect:srcTopR operation:op fraction:delta];
    //
    //    [self drawInRect:dstMidL fromRect:srcMidL operation:op fraction:delta];
    //    [self drawInRect:dstMidC fromRect:srcMidC operation:op fraction:delta];
    //    [self drawInRect:dstMidR fromRect:srcMidR operation:op fraction:delta];
    //
    //    [self drawInRect:dstBotL fromRect:srcBotL operation:op fraction:delta];
    //    [self drawInRect:dstBotC fromRect:srcBotC operation:op fraction:delta];
    //    [self drawInRect:dstBotR fromRect:srcBotR operation:op fraction:delta];
    [resultImg unlockFocus];
    return resultImg;
}

+(NSImage *)image:(NSImage *)image leftCapWidth:(float)leftWidth middleWidth:(float)middleWidth rightCapWidth:(float)rightWidth
{
    
    // Calculate the new images dimensions
    float imageWidth = leftWidth + middleWidth + rightWidth;
    float imageHeight = image.size.height;
    
    // Generate the left image
    NSRect rectLeft = NSMakeRect(0, 0, leftWidth, imageHeight);
    NSImage *imageLeft = [[NSImage alloc] initWithSize:rectLeft.size];
    if (imageLeft.size.width > 0) {
        [imageLeft lockFocus];
        [image drawInRect:rectLeft fromRect:rectLeft operation:NSCompositeCopy fraction:1.0];
        [imageLeft unlockFocus];
    }
    
    // Generate the middle image
    NSRect rectMiddle = NSMakeRect(0, 0, image.size.width - (rightWidth + leftWidth), imageHeight);
    NSImage *imageMiddle = [[NSImage alloc] initWithSize:rectMiddle.size];
    if (imageMiddle.size.width > 0) {
        [imageMiddle lockFocus];
        [image drawInRect:rectMiddle fromRect:NSMakeRect(leftWidth, 0, rectMiddle.size.width, imageHeight) operation:NSCompositeCopy fraction:1.0];
        [imageMiddle unlockFocus];
    }
    
    // Generate the right image
    NSRect rectRight = NSMakeRect(0, 0, rightWidth, imageHeight);
    NSImage *imageRight = [[NSImage alloc] initWithSize:rectRight.size];
    if (imageRight.size.width > 0) {
        [imageRight lockFocus];
        [image drawInRect:rectRight fromRect:NSMakeRect(image.size.width - rightWidth, 0, rightWidth, imageHeight) operation:NSCompositeCopy fraction:1.0];
        [imageRight unlockFocus];
    }
    
    // Combine the images
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(imageWidth,  imageHeight)];
    if (newImage.size.width > 0) {
        [newImage lockFocus];
        NSDrawThreePartImage(NSMakeRect(0, 0, imageWidth, imageHeight), imageLeft, imageMiddle, imageRight, NO, NSCompositeSourceOver, 1, NO);
        [newImage unlockFocus];
    }
    
    // Release the images and return the new image
    
    return newImage;
}

@end