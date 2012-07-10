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

typedef void (^GAServiceStatusChangedHandler)(GAService *service);


@interface GAService : NSObject {
    NSMutableDictionary     *previousDeviceProxies;
    
    GACommandRunner         *commandRunner;
    GAAutoscrollTextView    *outputTextView;
    GAServiceStatusChangedHandler   statusChangedHandler;
}

+ (id)sharedService;

- (BOOL)hasConfigured;

- (BOOL)supportReconnectAfterDisconnected;

- (NSString *)configTemplate;

- (NSString *)configPath;

- (NSString *)configValueForKey:(NSString *)key;

- (void)writeConfigFile;

- (NSString *)serviceName;

- (NSString *)serviceTitle;

- (NSString *)serviceWorkDirectory;

- (int)proxyPort;

- (NSString *)proxySetting;

- (void)notifyStatusChanged;

- (void)setupWorkDirectory;

- (void)setupCommandRunner;

- (BOOL)isRunning;

- (void)toggleSystemProxy:(BOOL)useProxy;

- (void)start;

- (void)stop;

@property (nonatomic, strong)   GAAutoscrollTextView        *outputTextView;
@property (nonatomic, copy)     GAServiceStatusChangedHandler   statusChangedHandler;

@end
