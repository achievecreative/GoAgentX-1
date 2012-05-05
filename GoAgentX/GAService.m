//
//  GAService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-24.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#define NOT_IMPL  @throw [[NSException alloc] initWithName:@"NotImplenmentException" reason:@"__PRETTY_FUNCTION__" userInfo:nil];

#import "GAService.h"

#import "GAConfigFieldManager.h"
#import "GAPACHTTPServer.h"

@interface GAService ()

- (NSString *)serviceWorkDirectory;

@end


@implementation GAService

@synthesize statusChangedHandler;
@synthesize outputTextView;

static NSMutableDictionary *sharedContainer = nil;

+ (void)initialize {
    if (self == [GAService class]) {
        sharedContainer = [NSMutableDictionary new];
    }
}


+ (id)sharedService {
    NSString *key = NSStringFromClass(self);
    
	@synchronized(self) {
		if ([sharedContainer objectForKey:key] == nil) {
            [sharedContainer setObject:[[self alloc] init] forKey:key];
		}
	}
    
	return [sharedContainer objectForKey:key];
}


+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
        NSString *key = NSStringFromClass(self);
		if ([sharedContainer objectForKey:key] == nil) {
            [sharedContainer setObject:[super allocWithZone:zone] forKey:key];
            return [sharedContainer objectForKey:key];
		}
	}
    
	return nil;
}


- (id)copyWithZone:(NSZone *)zone {
	return self;
}


- (id)init {
    if (self = [super init]) {
        previousDeviceProxies = [NSMutableDictionary new];
    }
    
    return self;
}


- (BOOL)hasConfigured {
    NOT_IMPL
}


- (NSString *)configTemplate {
    NOT_IMPL
}


- (NSString *)configPath {
    NOT_IMPL
}


- (NSString *)serviceTitle {
    NOT_IMPL
}


- (int)proxyPort {
    return 0;
}


- (NSString *)proxySetting {
    return nil;
}


- (void)notifyStatusChanged {
    // 如果有设置自动切换系统代理设置，切换系统代理设置
    if ([self proxySetting] != nil && [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:AutoToggleSystemProxySettings"]) {
        [self toggleSystemProxy:[self isRunning]];
    }

    if (statusChangedHandler) {
        statusChangedHandler(self);
    }
}


- (void)setupCommandRunner {
    if (commandRunner == nil) {
        commandRunner = [GACommandRunner new];
    }
    
    commandRunner.outputTextView = self.outputTextView;
    commandRunner.workDirectory = [self serviceWorkDirectory];
    
    __block id _self = self;
    commandRunner.terminationHandler = ^(NSTask *task) {
        [_self notifyStatusChanged];
    };
}


- (BOOL)isRunning {
    BOOL running = [commandRunner isTaskRunning];
    return running;
}


- (void)start {
    if (![self hasConfigured]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"请进行服务配置"
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert runModal];
        return;
    }
    
    if (![commandRunner isTaskRunning]) {
        [self.outputTextView appendString:@"正在启动...\n"];
        
        // 关闭可能的上次运行的进程
        NSInteger lastRunPID = [[NSUserDefaults standardUserDefaults] integerForKey:@"GoAgent:LastRunPID"];
        if (lastRunPID > 0 && kill((int)lastRunPID, 0) == 0) {
            kill((int)lastRunPID, 9);
        }
        
        [self setupWorkDirectory];
        [self setupCommandRunner];
        [commandRunner run];
        
        [self.outputTextView appendString:@"启动完成\n"];
        [[NSUserDefaults standardUserDefaults] setInteger:[commandRunner processId] forKey:@"GoAgent:LastRunPID"];
        
        [self notifyStatusChanged];
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


- (NSString *)configValueForKey:(NSString *)key {
    return [[GAConfigFieldManager sharedManager] configValueForKey:key ofService:[self serviceName]];
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
    if ([self configPath] == nil) {
        return;
    }
    
    NSDictionary *defaults = [self defaultsSettings];
    NSDictionary *valuesMap = [self defaultsValueMap];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *configContent = [self configTemplate];
    
    for (NSString *key in [defaults allKeys]) {
        NSString *value = [userDefaults stringForKey:key] ?: @"";
        NSArray *valueMap = [valuesMap objectForKey:key];
        
        if (valueMap != nil) {
            value = [valueMap objectAtIndex:[value intValue]];
        }
        
        configContent = [configContent stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key]
                                                                 withString:value ?: @""];
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
        NSInteger proxyPort = [self proxyPort];
        NSString *proxySetting = [self proxySetting];
        
        BOOL usePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:AutoToggleSystemProxyWithPAC"];
        BOOL useCustomePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:UseCustomPACAddress"];
        NSString *customPAC = [[NSUserDefaults standardUserDefaults] stringForKey:@"GoAgent:CustomPACAddress"];
        NSString *pacFile = useCustomePAC ? customPAC : [[GAPACHTTPServer sharedServer] pacAddressForProxy:[self proxySetting]];
        
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
        
        if (usePAC) {
            [proxies setObject:pacFile forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
            
        } else if ([proxySetting hasPrefix:@"PROXY"]) {
            [proxies setObject:[NSNumber numberWithInteger:proxyPort] forKey:(NSString *)kCFNetworkProxiesHTTPPort];
            [proxies setObject:@"127.0.0.1" forKey:(NSString *)kCFNetworkProxiesHTTPProxy];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
            
        } else if ([proxySetting hasPrefix:@"SOCKS"]) {
            [proxies setObject:[NSNumber numberWithInteger:proxyPort] forKey:(NSString *)kCFNetworkProxiesSOCKSPort];
            [proxies setObject:@"127.0.0.1" forKey:(NSString *)kCFNetworkProxiesSOCKSProxy];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
        }
        
    } else {
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
    }
}


- (void)toggleSystemProxy:(BOOL)useProxy {
    BOOL usePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:AutoToggleSystemProxyWithPAC"];
    NSLog(@"Toggle system proxy %@ with PAC %@", useProxy ? @"YES" : @"NO", usePAC ? @"YES" : @"NO");
    
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
