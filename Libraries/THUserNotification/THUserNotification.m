//
//  THUserNotification.m
//  NotificationDemo
//
//  Created by TanHao on 12-8-15.
//  Copyright (c) 2012年 TanHao. All rights reserved.
//

#import "THUserNotification.h"
#import "McAnimationUtility.h"
#import <QuartzCore/QuartzCore.h>

#define McShowPoint(aWindow) (NSMakePoint(NSWidth([NSScreen mainScreen].frame)-NSWidth(aWindow.frame),NSHeight([NSScreen mainScreen].frame)-NSHeight(aWindow.frame)-20))

@protocol THUserNotificationDelegate <NSObject>

- (BOOL)userNotificationWillActivate:(THUserNotification *)notification;
- (void)userNotification:(THUserNotification *)notification didActivateType:(THUserNotificationActivationType)type;

@end

@interface THUserNotification()<NSAnimationDelegate>
@property (strong) NSWindow *showWindow;
@property (strong) NSImageView *iconView;
@property (strong) NSTextField *titleField;
@property (strong) NSTextField *subtitleField;
@property (strong) NSTextField *informativeField;
@property (strong) NSButton *bgButton;
@property (strong) NSButton *actionButton;
@property (strong) NSButton *otherButton;
@property (assign,getter = isVisible) BOOL visible;
@property (assign,getter = isAnimating) BOOL animating;
@property (strong) NSViewAnimation *viewAnimation;

@property (assign) id<THUserNotificationDelegate> delegate;

- (void)presentedNotification;

@end

@implementation THUserNotification
@synthesize title;
@synthesize subtitle;
@synthesize informativeText;
@synthesize actionButtonTitle;
@synthesize userInfo;
@synthesize deliveryDate;
@synthesize deliveryTimeZone;
@synthesize deliveryRepeatInterval;
@synthesize actualDeliveryDate;
@synthesize presented;
@synthesize remote;
@synthesize soundName;
@synthesize hasActionButton;
@synthesize bgButton;
@synthesize activationType;
@synthesize otherButtonTitle;

@synthesize showWindow;
@synthesize iconView;
@synthesize titleField;
@synthesize subtitleField;
@synthesize informativeField;
@synthesize actionButton;
@synthesize otherButton;
@synthesize visible;
@synthesize animating;
@synthesize viewAnimation;

@synthesize delegate;

+ (id)notification
{
    Class aClass = NSClassFromString(@"NSUserNotification");
    if (aClass == nil)
    {
        aClass = [self class];
    }
    
    id instance = [[aClass alloc] init];
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        hasActionButton = YES;
        
        //create UI
        showWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 328, 100)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
        [showWindow setReleasedWhenClosed:NO];
        [showWindow setMovableByWindowBackground:NO];
        [showWindow setBackgroundColor:[NSColor clearColor]];
        [showWindow setLevel:NSStatusWindowLevel];
        [showWindow setOpaque:NO];
        [showWindow setHasShadow:YES];
        [showWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        
        static NSImage *bgImg = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *bgPath = [[NSBundle bundleForClass:self.class] pathForImageResource:@"banner2lines"];
            bgImg = [[NSImage alloc] initWithContentsOfFile:bgPath];
            //bgImg = [NSImage image:bgImg leftCapWidth:30 middleWidth:NSWidth(showWindow.frame)-60 rightCapWidth:30];
            bgImg = [bgImg drawStretchableInRect:[[showWindow contentView] bounds] edgeInsets:NSEdgeInsetsMake(30, 30, 30, 30)];
        });
        NSImageView *bgView = [[NSImageView alloc] initWithFrame:[[showWindow contentView] bounds]];
        [bgView setImageScaling:NSImageScaleAxesIndependently];
        [bgView.cell setImageScaling:NSImageScaleAxesIndependently];
        [bgView setImage:bgImg];
        [[showWindow contentView] addSubview:bgView];
        
        NSString *iconPath = [[NSBundle mainBundle] bundlePath];
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
        [icon setSize:NSMakeSize(32, 32)];
        iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(20, 50, 32, 32)];
        [iconView setImageScaling:NSScaleProportionally];
        [iconView setImageAlignment:NSImageAlignCenter];
        [iconView setImage:icon];
        [[showWindow contentView] addSubview:iconView];
        
        titleField = [[NSTextField alloc] initWithFrame:NSMakeRect(56, 62, 180, 18)];
        [titleField setAlignment:NSLeftTextAlignment];
        [titleField setFont:[NSFont systemFontOfSize:13]];
        float colorDeep = 50;
        [titleField setTextColor:[NSColor colorWithCalibratedRed:colorDeep/255 green:colorDeep/255 blue:colorDeep/255 alpha:1.0]];
        [titleField.cell setTruncatesLastVisibleLine:YES];
        [titleField setSelectable:NO];
        [titleField setEditable:NO];
        [titleField setBordered:NO];
        [titleField setDrawsBackground:NO];
        
        subtitleField = [[NSTextField alloc] initWithFrame:NSMakeRect(56, 44, 190, 18)];
        [subtitleField setAlignment:NSLeftTextAlignment];
        [subtitleField setFont:[NSFont systemFontOfSize:12]];
        colorDeep = 70;
        [subtitleField setTextColor:[NSColor colorWithCalibratedRed:colorDeep/255 green:colorDeep/255 blue:colorDeep/255 alpha:1.0]];
        [subtitleField.cell setTruncatesLastVisibleLine:YES];
        [subtitleField setSelectable:NO];
        [subtitleField setEditable:NO];
        [subtitleField setBordered:NO];
        [subtitleField setDrawsBackground:NO];
        
        informativeField = [[NSTextField alloc] initWithFrame:NSMakeRect(56, 26, 190, 18)];
        [informativeField setAlignment:NSLeftTextAlignment];
        [informativeField setFont:[NSFont systemFontOfSize:11]];
        colorDeep = 90;
        [informativeField setTextColor:[NSColor colorWithCalibratedRed:colorDeep/255 green:colorDeep/255 blue:colorDeep/255 alpha:1.0]];
        [informativeField.cell setTruncatesLastVisibleLine:YES];
        [informativeField setSelectable:NO];
        [informativeField setEditable:NO];
        [informativeField setBordered:NO];
        [informativeField setDrawsBackground:NO];
        
        [[showWindow contentView] addSubview:titleField];
        [[showWindow contentView] addSubview:subtitleField];
        [[showWindow contentView] addSubview:informativeField];
        
        bgButton = [[NSButton alloc] initWithFrame:[[showWindow contentView] bounds]];
        [bgButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [bgButton setButtonType:NSToggleButton];
        [bgButton setBordered:NO];
        [bgButton setTitle:@""];
        [bgButton setTarget:self];
        [bgButton setAction:@selector(buttonClick:)];
        [[showWindow contentView] addSubview:bgButton];
        
        actionButton = [[NSButton alloc] initWithFrame:NSMakeRect(254, 30, 52, 22)];
        [actionButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [actionButton setButtonType:NSToggleButton];
        [actionButton setTarget:self];
        [actionButton setAction:@selector(buttonClick:)];
        
        otherButton = [[NSButton alloc] initWithFrame:NSMakeRect(254, 58, 52, 22)];
        [otherButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [otherButton setButtonType:NSToggleButton];
        [otherButton setTarget:self];
        [otherButton setAction:@selector(buttonClick:)];
        
        [[showWindow contentView] addSubview:actionButton];
        [[showWindow contentView] addSubview:otherButton];
    }
    return self;
}

- (void)presentedNotification
{
    presented = YES;
    actualDeliveryDate = [NSDate date];
}

- (void)setup:(THUserNotificationCenterType)type
{
    //default value
    titleField.stringValue = @"";
    subtitleField.stringValue = @"";
    informativeField.stringValue = @"";
    [actionButton setTitle:@"Show"];
    [otherButton setTitle:@"Close"];
    [actionButton setHidden:NO];
    [otherButton setHidden:NO];
    
    titleField.frame = NSMakeRect(56, 62, 180, 18);
    subtitleField.frame = NSMakeRect(56, 44, 190, 18);
    informativeField.frame = NSMakeRect(56, 26, 190, 18);
    
    //set UI value
    if (self.title) titleField.stringValue = self.title;
    if (self.subtitle) subtitleField.stringValue = self.subtitle;
    if (self.informativeText) informativeField.stringValue = self.informativeText;
    if (self.actionButtonTitle) [actionButton setTitle:self.actionButtonTitle];
    if (self.otherButtonTitle) [otherButton setTitle:self.otherButtonTitle];

    [actionButton setHidden:!hasActionButton];
    
    if (type == THUserNotificationCenterTypeBanner)
    {
        [actionButton setHidden:YES];
        [otherButton setHidden:YES];
        
        titleField.frame = NSMakeRect(56, 62, 240, 18);
        subtitleField.frame = NSMakeRect(56, 44, 250, 18);
        informativeField.frame = NSMakeRect(56, 26, 250, 18);
    }
}

- (void)buttonClick:(id)sender
{
    if ([sender isKindOfClass:[NSButton class]])
    {
        [sender setState:NSOffState];
    }
    
    if (![delegate userNotificationWillActivate:self])
    {
        return;
    }
    
    THUserNotificationActivationType type = THUserNotificationActivationTypeNone;
    if (sender == actionButton)
    {
        type = THUserNotificationActivationTypeActionButtonClicked;
    }
    else if (sender == bgButton)
    {
        type = THUserNotificationActivationTypeContentsClicked;
    }
    activationType = type;
    [delegate userNotification:self didActivateType:type];
}

#pragma mark -
#pragma mark Animation

- (void)moveInAnimation
{
    if (animating)
    {
        return;
    }
    animating = YES;
    visible = YES;
    NSPoint startPoint = NSMakePoint(McShowPoint(showWindow).x,
                                     NSHeight([NSScreen mainScreen].frame));
    [showWindow setFrameOrigin:startPoint];
    NSPoint endPoint = McShowPoint(showWindow);
    
    [showWindow orderFront:nil];
    [[showWindow contentView] setWantsLayer:YES];
    [McAnimationUtility setAnchorPoint:CGPointMake(0.5, 0.0) forView:showWindow.contentView];
    
    NSTimeInterval duration = 0.5;
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.fromValue = [NSNumber numberWithFloat:M_PI/2];
    rotationAnimation.toValue = [NSNumber numberWithFloat:0];
    rotationAnimation.duration = duration;
    rotationAnimation.delegate = self;
    [[[showWindow contentView] layer] addAnimation:rotationAnimation forKey:@"rotation"];
    
    NSRect startRect = showWindow.frame;
    startRect.origin = startPoint;
    NSRect endRect = showWindow.frame;
    endRect.origin = endPoint;
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                showWindow,NSViewAnimationTargetKey,
                                [NSValue valueWithRect:startRect],NSViewAnimationStartFrameKey,
                                [NSValue valueWithRect:endRect],NSViewAnimationEndFrameKey,
                                NSViewAnimationFadeInEffect,NSViewAnimationEffectKey,nil];
    viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dictionary]];
    [viewAnimation setDuration:duration];
    [viewAnimation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [viewAnimation setDelegate:self];
    [viewAnimation startAnimation];
}

- (void)moveAnimation:(NSPoint)point
{
    if (animating)
    {
        return;
    }
    
    animating = YES;
    NSTimeInterval duration = 0.5;
    NSRect startRect = showWindow.frame;
    NSRect endRect = showWindow.frame;
    endRect.origin = point;
    if (NSEqualRects(startRect, endRect))
    {
        animating = NO;
        return;
    }
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                showWindow,NSViewAnimationTargetKey,
                                [NSValue valueWithRect:startRect],NSViewAnimationStartFrameKey,
                                [NSValue valueWithRect:endRect],NSViewAnimationEndFrameKey,nil];
    viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dictionary]];
    [viewAnimation setDuration:duration];
    [viewAnimation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [viewAnimation setDelegate:self];
    [viewAnimation startAnimation];
}

- (void)moveOutAnimation
{
    if (animating)
    {
        return;
    }
    animating = YES;
    visible = NO;
    NSPoint endPoint = [self.showWindow frame].origin;
    endPoint.x = NSWidth([NSScreen mainScreen].frame)-NSWidth(self.showWindow.frame)/2;
    
    NSTimeInterval duration = 0.5;
    NSRect startRect = showWindow.frame;
    NSRect endRect = showWindow.frame;
    endRect.origin = endPoint;
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                showWindow,NSViewAnimationTargetKey,
                                [NSValue valueWithRect:startRect],NSViewAnimationStartFrameKey,
                                [NSValue valueWithRect:endRect],NSViewAnimationEndFrameKey,
                                NSViewAnimationFadeOutEffect,NSViewAnimationEffectKey,nil];
    viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dictionary]];
    [viewAnimation setDuration:duration];
    [viewAnimation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [viewAnimation setDelegate:self];
    [viewAnimation startAnimation];
    
}

- (void)fadeOutAnimation
{
    if (animating)
    {
        return;
    }
    animating = YES;
    visible = NO;
    NSTimeInterval duration = 0.5;
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                showWindow,NSViewAnimationTargetKey,
                                NSViewAnimationFadeOutEffect,NSViewAnimationEffectKey,nil];
    viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dictionary]];
    [viewAnimation setDuration:duration];
    [viewAnimation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [viewAnimation setDelegate:self];
    [viewAnimation startAnimation];
}

- (void)animationFinished:(NSAnimation*)animation
{
    [[[showWindow contentView] layer] removeAllAnimations];
    [[showWindow contentView] setWantsLayer:NO];
    animating = NO;
    
    if (animation)
    {
        NSArray *viewAnimations = [(NSViewAnimation *)animation viewAnimations];
        if ([viewAnimations count] == 0)
        {
            return;
        }
        NSDictionary *info = [viewAnimations objectAtIndex:0];
        if ([info objectForKey:NSViewAnimationEffectKey] == NSViewAnimationFadeOutEffect)
        {
            [showWindow orderOut:nil];
        }
    }
}

- (void)animationDidEnd:(NSAnimation*)animation
{
    [self performSelectorOnMainThread:@selector(animationFinished:) withObject:animation waitUntilDone:NO];
}

- (void)animationDidStop:(NSAnimation*)animation
{
    [self animationDidEnd:animation];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [self animationFinished:nil];
}

@end


@interface THUserNotificationCenter ()<THUserNotificationDelegate>
@property (strong) NSTimer *timer;
@end

@implementation THUserNotificationCenter
@synthesize delegate;
@synthesize deliveredNotifications;
@synthesize scheduledNotifications;
@synthesize timer;
@synthesize centerType;

+ (id)notificationCenter
{
    Class aClass = NSClassFromString(@"NSUserNotificationCenter");
    if (aClass == nil)
    {
        aClass = [self class];
    }
    
    return [aClass defaultUserNotificationCenter];
}

+ (THUserNotificationCenter *)defaultUserNotificationCenter
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        centerType = THUserNotificationCenterTypeAlert;
        scheduledNotifications = [[NSMutableArray alloc] init];
        deliveredNotifications = [[NSMutableArray alloc] init];
        timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0 target:self selector:@selector(checkMethod:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)sortVisibleNotifications
{
    NSMutableArray *visibleNotifications = [NSMutableArray array];
    for (THUserNotification *aNotification in deliveredNotifications)
    {
        if (aNotification.isVisible)
        {
            [visibleNotifications addObject:aNotification];
        }
    }
    //按实际递交时间排序,最近递交的在前面
    [visibleNotifications sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return 0-[[(THUserNotification *)obj1 actualDeliveryDate] compare:[(THUserNotification *)obj2 actualDeliveryDate]];
    }];
    
    int maxShowCount = 6;
    for (int i=0;i<[visibleNotifications count];i++)
    {
        THUserNotification *aNotification = [visibleNotifications objectAtIndex:i];
        [aNotification.showWindow setLevel:NSStatusWindowLevel+[visibleNotifications count]-i];
        NSPoint point = McShowPoint(aNotification.showWindow);
        if (i < maxShowCount)
        {
            point.y -= i*(NSHeight(aNotification.showWindow.frame)-10);
        }
        else if ( i < maxShowCount+2)
        {
            point.y -= (maxShowCount-1)*(NSHeight(aNotification.showWindow.frame)-10)+(i-maxShowCount+1)*5;
        }else
        {
            point.y -= (maxShowCount-1)*(NSHeight(aNotification.showWindow.frame)-10)+3*5;
        }
        [aNotification moveAnimation:point];
    }
}

- (void)presentedNotification:(THUserNotification *)notification
{
    if (![deliveredNotifications containsObject:notification])
    {
        [(NSMutableArray *)deliveredNotifications addObject:notification];
    }
    if ([scheduledNotifications containsObject:notification])
    {
        [(NSMutableArray *)scheduledNotifications removeObject:notification];
    }
    
    if (notification.isVisible)
    {
        [notification setup:centerType];
        [notification presentedNotification];
        [self sortVisibleNotifications];
        return;
    }
    
    //显现该条消息
    [notification setup:centerType];
    notification.delegate = self;
    [notification presentedNotification];
    [notification moveInAnimation];
    
    
    //重新排列已经显示的消息
    [self sortVisibleNotifications];
    
    if ([delegate respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)])
    {
        [delegate userNotificationCenter:self didDeliverNotification:notification];
    }
}

- (void)checkMethod:(id)sender
{
    //如果有动画在执行，则跳过
    for (THUserNotification *aNotification in deliveredNotifications)
    {
        if (aNotification.isAnimating)
        {
            return;
        }
    }
    
    //如果设置通知的样式为空，则跳过
    if (centerType == THUserNotificationActivationTypeNone)
    {
        return;
    }
    
    //防止在快速循环中对数组进行修改
    NSArray *scheduledNotificationsCopy = [scheduledNotifications copy];
    NSArray *deliveredNotificationsCopy = [deliveredNotifications copy];
    
    //如果通知样式为横幅，检测是否已经显示超过5秒，如果是则移出
    if (centerType == THUserNotificationCenterTypeBanner)
    {
        for (THUserNotification *aNotification in deliveredNotificationsCopy)
        {
            if (aNotification.isVisible)
            {
                if ([aNotification.actualDeliveryDate timeIntervalSinceNow] <= -5)
                {
                    [aNotification moveOutAnimation];
                }else
                {
                    //如果当前横幅显示在5秒之内，则跳出，让它继续展示
                    return;
                }
            }
        }
    }
    
    //先检测是否有计划任务触发(相比周期任务优先级高一些)
    for (THUserNotification *aNotification in scheduledNotificationsCopy)
    {
        if ([[aNotification deliveryDate] timeIntervalSinceNow] <= 0)
        {
            [self presentedNotification:aNotification];
            return;
        }
    }
    
    //然后检测是否有周期性任务触发
    for (THUserNotification *aNotification in deliveredNotificationsCopy)
    {
        if (aNotification.deliveryRepeatInterval)
        {
            NSDateComponents *comps = aNotification.deliveryRepeatInterval;
            NSTimeInterval interval = 0;
            //if ([comps year]!=NSUndefinedDateComponent) interval+=[comps year]*(365*24*60*60);
            //if ([comps month]!=NSUndefinedDateComponent) interval+=[comps month]*(30*24*60*60);
            if ([comps weekday]!=NSUndefinedDateComponent) interval+=[comps weekday]*(7*60*60);
            if ([comps day]!=NSUndefinedDateComponent) interval+=[comps day]*(24*60*60);
            if ([comps hour]!=NSUndefinedDateComponent) interval+=[comps hour]*(60*60);
            if ([comps minute]!=NSUndefinedDateComponent) interval+=[comps minute]*60;
            if ([comps second]!=NSUndefinedDateComponent) interval+=[comps second];
            
            if (interval < 60)
            {
                continue;
            }
            
            NSDate *date = [aNotification.actualDeliveryDate dateByAddingTimeInterval:interval];
            
            if ([date timeIntervalSinceNow] <= 0)
            {
                [self presentedNotification:aNotification];
                return;
            }
        }
    }
}

- (THUserNotificationCenterType)centerType
{
    return centerType;
}

- (void)setCenterType:(THUserNotificationCenterType)type
{
    centerType = type;
    if (centerType == THUserNotificationCenterTypeBanner || centerType == THUserNotificationCenterTypeNone)
    {
        NSArray *deliveredNotificationsCopy = [deliveredNotifications copy];
        for (THUserNotification *aNotification in deliveredNotificationsCopy)
        {
            if (aNotification.isVisible)
            {
                [aNotification moveOutAnimation];
            }
        }
    }
}

- (void)scheduleNotification:(THUserNotification *)notification
{
    if (![scheduledNotifications containsObject:notification])
    {
        [(NSMutableArray *)scheduledNotifications addObject:notification];
    }
}

- (void)removeScheduledNotification:(THUserNotification *)notification
{
    [(NSMutableArray *)scheduledNotifications removeObject:notification];
}

- (void)deliverNotification:(THUserNotification *)notification
{
    if (centerType == THUserNotificationCenterTypeNone)
    {
        if (![deliveredNotifications containsObject:notification])
        {
            [(NSMutableArray *)deliveredNotifications addObject:notification];
        }
        return;
    }
    
    if (centerType == THUserNotificationCenterTypeBanner)
    {
        NSArray *deliveredNotificationsCopy = [deliveredNotifications copy];
        for (THUserNotification *aNotification in deliveredNotificationsCopy)
        {
            if (aNotification.isVisible)
            {
                [aNotification moveOutAnimation];
            }
        }
    }
    
    [self presentedNotification:notification];
}

- (void)removeDeliveredNotification:(THUserNotification *)notification
{
    [(NSMutableArray *)deliveredNotifications removeObject:notification];
}

- (void)removeAllDeliveredNotifications
{
    [(NSMutableArray *)deliveredNotifications removeAllObjects];
}

#pragma mark -
#pragma mark THUserNotificationDelegate

- (BOOL)userNotificationWillActivate:(THUserNotification *)notification
{
    for (THUserNotification *aNotification in deliveredNotifications)
    {
        if (aNotification.isAnimating)
        {
            return NO;
        }
    }
    return YES;
}

- (void)userNotification:(THUserNotification *)notification didActivateType:(THUserNotificationActivationType)type
{
    if (centerType == THUserNotificationCenterTypeBanner)
    {
        [notification moveOutAnimation];
    }else
    {
        if (type == THUserNotificationActivationTypeNone || type == THUserNotificationActivationTypeActionButtonClicked)
        {
            [notification fadeOutAnimation];
            [self sortVisibleNotifications];
        }
    }
    if (type != THUserNotificationActivationTypeNone &&
        [delegate respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)])
    {
        [delegate userNotificationCenter:self didActivateNotification:notification];
    }
}

@end