//
//  GAService.h
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-24.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GACommandRunner.h"

@class GAService;


@protocol GAServiceDelegate <NSObject>

- (void)serviceStatusChanged:(GAService *)service;

@end


@interface GAService : NSObject {
    NSMutableDictionary     *previousDeviceProxies;
    
    GACommandRunner         *commandRunner;
    GAAutoscrollTextView    *outputTextView;
}

+ (id)sharedService;

- (BOOL)hasConfigured;

- (NSString *)configTemplate;

- (NSString *)configPath;

- (void)writeConfigFile;

- (void)setupWorkDirectory;

- (void)setupCommandRunner;

- (BOOL)isRunning;

- (void)toggleSystemProxy:(BOOL)useProxy;

- (void)start;

- (void)stop;

@property (nonatomic, assign)   id<GAServiceDelegate>       delegate;
@property (nonatomic, strong)   GAAutoscrollTextView        *outputTextView;

@end
