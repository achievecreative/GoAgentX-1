//
//  THUserNotification.h
//  NotificationDemo
//
//  Created by TanHao on 12-8-15.
//  Copyright (c) 2012年 TanHao. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
typedef NS_ENUM(NSInteger, THUserNotificationActivationType) {
    THUserNotificationActivationTypeNone = NSUserNotificationActivationTypeNone,
    THUserNotificationActivationTypeContentsClicked = NSUserNotificationActivationTypeContentsClicked,
    THUserNotificationActivationTypeActionButtonClicked = NSUserNotificationActivationTypeActionButtonClicked
};

typedef NS_ENUM(NSInteger, THUserNotificationCenterType) {
    THUserNotificationCenterTypeNone = 0,
    THUserNotificationCenterTypeBanner = 1,
    THUserNotificationCenterTypeAlert = 2
};
 */

enum
{
    THUserNotificationActivationTypeNone = 0,
    THUserNotificationActivationTypeContentsClicked = 1,
    THUserNotificationActivationTypeActionButtonClicked = 2
};
typedef NSInteger THUserNotificationActivationType;

enum
{
    THUserNotificationCenterTypeNone = 0,
    THUserNotificationCenterTypeBanner = 1,
    THUserNotificationCenterTypeAlert = 2
};
typedef NSInteger THUserNotificationCenterType;


@interface THUserNotification : NSObject

@property (copy) NSString *title;

@property (copy) NSString *subtitle;

@property (copy) NSString *informativeText;

@property (copy) NSString *actionButtonTitle;

@property (copy) NSDictionary *userInfo;

@property (copy) NSDate *deliveryDate;

@property (copy) NSTimeZone *deliveryTimeZone;

//just support: weekDay,day,hour,minute,second，Not less than one minute
@property (copy) NSDateComponents *deliveryRepeatInterval;

@property (readonly) NSDate *actualDeliveryDate;

@property (readonly, getter=isPresented) BOOL presented;

@property (readonly, getter=isRemote) BOOL remote;

@property (copy) NSString *soundName;

@property BOOL hasActionButton;

@property (readonly) THUserNotificationActivationType activationType;

@property (copy) NSString *otherButtonTitle;

//extern method
+ (id)notification;//Auto selete Class(NSUserNotification/THUserNotification)

@end

@protocol THUserNotificationCenterDelegate;
@interface THUserNotificationCenter : NSObject
@property (assign) id <THUserNotificationCenterDelegate> delegate;
@property (copy) NSArray *scheduledNotifications;
@property (readonly) NSArray *deliveredNotifications;

+ (THUserNotificationCenter *)defaultUserNotificationCenter;

- (void)scheduleNotification:(THUserNotification *)notification;

- (void)removeScheduledNotification:(THUserNotification *)notification;

- (void)deliverNotification:(THUserNotification *)notification;

- (void)removeDeliveredNotification:(THUserNotification *)notification;

- (void)removeAllDeliveredNotifications;

//extern method
@property (assign) THUserNotificationCenterType centerType;
+ (id)notificationCenter;//Auto selete Class(NSUserNotificationCenter/THUserNotificationCenter)

@end

@protocol THUserNotificationCenterDelegate <NSObject>

- (void)userNotificationCenter:(THUserNotificationCenter *)center didDeliverNotification:(THUserNotification *)notification;

- (void)userNotificationCenter:(THUserNotificationCenter *)center didActivateNotification:(THUserNotification *)notification;

- (BOOL)userNotificationCenter:(THUserNotificationCenter *)center shouldPresentNotification:(THUserNotification *)notification;

@end