//
//  GAService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-24.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#define NOT_IMPL  @throw [[NSException alloc] initWithName:@"NotImplenmentException" reason:@"__PRETTY_FUNCTION__" userInfo:nil];

#import "GAService.h"

#import "SynthesizeSingleton.h"

@implementation GAService

@synthesize delegate;
@synthesize outputTextView;

SYNTHESIZE_SINGLETON_FOR_CLASS(GAService, Service)

- (BOOL)hasConfigured {
    NOT_IMPL
}


- (NSString *)configTemplate {
    NOT_IMPL
}


- (NSString *)configPath {
    NOT_IMPL
}


- (void)notifyStatusChanged {
    if ([self.delegate conformsToProtocol:@protocol(GAServiceDelegate)]) {
        [self.delegate serviceStatusChanged:self];
    }
}


- (void)setupCommandRunner {
    if (commandRunner == nil) {
        commandRunner = [GACommandRunner new];
    }
    
    commandRunner.outputTextView = self.outputTextView;
    
    __block id _self = self;
    commandRunner.terminationHandler = ^(NSTask *task) {
        [_self notifyStatusChanged];
    };
}


- (BOOL)isRunning {
    return [commandRunner isTaskRunning];
}


- (void)start {
    if (![commandRunner isTaskRunning]) {
        // 关闭可能的上次运行的进程
        NSInteger lastRunPID = [[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:LastRunPID"];
        if (lastRunPID > 0) {
            kill((int)lastRunPID, 9);
        }
        
        [self setupWorkDirectory];
        [self setupCommandRunner];
        [commandRunner run];
    }
}


- (void)stop {
    if ([commandRunner isTaskRunning]) {
        [commandRunner terminateTask];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GoAgent:LastRunPID"];
        [self notifyStatusChanged];
    }
}


- (NSString *)serviceName {
    NOT_IMPL
}


- (NSString *)pathInApplicationSupportFolder:(NSString *)path {
    NSString *folder = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                         stringByAppendingPathComponent:@"Application Support"]
                        stringByAppendingPathComponent:@"GoAgentX"];
    return [folder stringByAppendingPathComponent:path];
}


- (NSString *)serviceWorkDirectory {
    return [self pathInApplicationSupportFolder:[self serviceName]];
}


- (NSDictionary *)defaultsSettings {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoAgentXDefaultsSettings" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    return dict;
}


- (NSDictionary *)defaultsValueMap {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoAgentXDefaultsValueMap" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    return dict;
}


- (void)writeConfigFile {
    NSDictionary *defaults = [self defaultsSettings];
    NSDictionary *valuesMap = [self defaultsValueMap];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *configContent = [self configTemplate];
    
    for (NSString *key in [defaults allKeys]) {
        NSObject *value = [userDefaults stringForKey:key] ?: @"";
        NSArray *valueMap = [valuesMap objectForKey:key];
        
        if ([value isKindOfClass:[NSNumber class]] && valuesMap != nil) {
            value = [valueMap objectAtIndex:[(NSNumber *)value intValue]];
        }
        
        configContent = [configContent stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key]
                                                                 withString:[value description]];
    }
    
    NSString *path = [[self serviceWorkDirectory] stringByAppendingPathComponent:[self configPath]];
    [configContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}


- (void)setupWorkDirectory {
    NSString *srcPath = [[NSBundle mainBundle] pathForResource:[self serviceName] ofType:@""];
    NSString *destPath = [self pathInApplicationSupportFolder:[self serviceName]];
    
    [[NSFileManager defaultManager] removeItemAtPath:destPath error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:[destPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:destPath error:NULL];
    
    [self writeConfigFile];
}


#pragma mark -
#pragma mark 代理设置

- (NSString *)proxiesPathOfDevice:(NSString *)devId {
    NSString *path = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, devId, kSCEntNetProxies];
    return path;
}


//! 修改代理设置的字典
- (void)modifyPrefProxiesDictionary:(NSMutableDictionary *)proxies withProxyEnabled:(BOOL)enabled {
    if (enabled) {
        NSInteger proxyPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:Local:Port"];
        BOOL usePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:AutoToggleSystemProxyWithPAC"];
        BOOL useCustomePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:UseCustomPACAddress"];
        NSString *customPAC = [[NSUserDefaults standardUserDefaults] stringForKey:@"GoAgent:CustomPACAddress"];
        NSString *pacFile = useCustomePAC ? customPAC : @"http://127.0.0.1:8089/goagent.pac";
        
        if (usePAC) {
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
            [proxies setObject:pacFile forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
            
        } else {
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
            [proxies setObject:[NSNumber numberWithInteger:proxyPort] forKey:(NSString *)kCFNetworkProxiesHTTPPort];
            [proxies setObject:@"127.0.0.1" forKey:(NSString *)kCFNetworkProxiesHTTPProxy];
        }
        
    } else {
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
    }
}


- (void)toggleSystemProxy:(BOOL)useProxy {
    SCPreferencesRef prefRef;// = SCPreferencesCreate(kCFAllocatorSystemDefault, CFSTR("test"), NULL);
    
    AuthorizationRef auth = nil;
	OSStatus authErr = noErr;
	
	AuthorizationFlags rootFlags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights 
    | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize;
	authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, rootFlags, &auth);
	if (authErr == noErr) {
		prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("GoAgentX"), nil, auth);
	} else {
        NSLog(@"Set system proxy failed");
        return;
    }
    
    NSDictionary *sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
    
    // 遍历系统中的网络设备列表，设置 AirPort 和 Ethernet 的代理
    for (NSString *key in [sets allKeys]) {
        NSMutableDictionary *dict = [sets objectForKey:key];
        NSString *hardware = [dict valueForKeyPath:@"Interface.Hardware"];
        if ([hardware isEqualToString:@"AirPort"] || [hardware isEqualToString:@"Ethernet"]) {
            [previousDeviceProxies setObject:[dict mutableCopy] forKey:key];
        }
    }
    
    if (useProxy) {        
        // 如果已经获取了旧的代理设置就直接用之前获取的，防止第二次获取到设置过的代理
        for (NSString *deviceId in previousDeviceProxies) {
            CFDictionaryRef proxies = SCPreferencesPathGetValue(prefRef, (__bridge CFStringRef)[self proxiesPathOfDevice:deviceId]);
            [self modifyPrefProxiesDictionary:(__bridge NSMutableDictionary *)proxies withProxyEnabled:YES];
            SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)[self proxiesPathOfDevice:deviceId], proxies);
        }
        
    } else {
        for (NSString *deviceId in previousDeviceProxies) {
            // 防止之前获取的代理配置还是启用了 SOCKS 代理或者 PAC 的，直接将两种代理方式禁用
            NSMutableDictionary *dict = [[previousDeviceProxies objectForKey:deviceId] objectForKey:(NSString *)kSCEntNetProxies];
            [self modifyPrefProxiesDictionary:dict withProxyEnabled:NO];
            SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)[self proxiesPathOfDevice:deviceId], (__bridge CFDictionaryRef)dict);
        }
        
        [previousDeviceProxies removeAllObjects];
    }
    
    SCPreferencesCommitChanges(prefRef);
    SCPreferencesApplyChanges(prefRef);
    SCPreferencesSynchronize(prefRef);
}


@end
