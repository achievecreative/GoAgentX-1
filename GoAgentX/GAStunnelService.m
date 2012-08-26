//
//  GAStunnelService.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-5-6.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAStunnelService.h"

@implementation GAStunnelService

+ (NSArray *)parseServicesList:(NSString *)text {
    text = [[[text stringByReplacingOccurrencesOfString:@" " withString:@""]
             stringByReplacingOccurrencesOfString:@"：" withString:@":"]
            stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    NSArray *services = [text componentsSeparatedByString:@"\n\n"];
    NSMutableArray *ret = [NSMutableArray new];
    
    @autoreleasepool {
        for (NSString *service in services) {
            if ([service stringByReplacingOccurrencesOfString:@"\n" withString:@""].length == 0) {
                continue;
            }
            
            NSMutableArray *servers = [NSMutableArray new];
            NSString *port = @"";
            NSArray *lines = [service componentsSeparatedByString:@"\n"];
            for (NSString *line in lines) {
                NSArray *parts = [line componentsSeparatedByString:@":"];
                if (parts.count == 3) {
                    port = port.length > 0 ? port : [parts objectAtIndex:0];
                    [servers addObject:[[parts subarrayWithRange:NSMakeRange(1, 2)] componentsJoinedByString:@":"]];
                } else if (parts.count == 2) {
                    [servers addObject:[parts componentsJoinedByString:@":"]];
                }
            }
            
            [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                            port,       @"port",
                            servers,    @"servers",
                            nil]];
        }
    }
    
    return ret;
}


+ (void)loadServices:(NSArray *)services toPopupButton:(NSPopUpButton *)popupButton {
    NSString *selected = [popupButton selectedItem].title;
    [popupButton removeAllItems];
    for (NSDictionary *service in services) {
        [popupButton addItemWithTitle:[[service objectForKey:@"servers"] componentsJoinedByString:@", "]];
    }
    [popupButton selectItemWithTitle:selected];
    if (popupButton.selectedItem == nil && popupButton.itemArray.count > 0) {
        [popupButton selectItemAtIndex:0];
    }
}


- (BOOL)hasConfigured {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:@"Stunnel:SelectedRemoteServer"].length > 0;
}


- (NSString *)configPath {
    return @"stunnel.conf";
}


- (NSString *)configTemplate {
    NSString *tpl = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"stunnel-config-template" ofType:@""]
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{Stunnel:WorkDirectory}" withString:[self serviceWorkDirectory]];
    
    // Write main proxy service
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *selectedServers = [[defaults stringForKey:@"Stunnel:SelectedRemoteServer"] ?: @"" componentsSeparatedByString:@", "];
    NSString *servers = [@"connect = " stringByAppendingString:[selectedServers componentsJoinedByString:@"\nconnect = "]];
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{Stunnel:RemoteServers}" withString:servers];
    
    // Write extra services
    NSMutableArray *extraServices = [NSMutableArray new];
    int proxyPort = [self proxyPort];
    int index = 0;
    NSString *remoteServers = [[NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:@"Stunnel:RemoteServerList"]] string];;
    NSArray *services = [[self class] parseServicesList:remoteServers];
    for (NSDictionary *service in services) {
        index++;
        proxyPort++;
        NSString *port = [service objectForKey:@"port"];
        NSArray *servers = [service objectForKey:@"servers"];
        [extraServices addObject:[NSString stringWithFormat:@"[proxy%d]", index]];
        [extraServices addObject:[NSString stringWithFormat:@"accept = 127.0.0.1:%d", port.length > 0 ? [port intValue] : proxyPort]];
        [extraServices addObject:[@"connect = " stringByAppendingString:[servers componentsJoinedByString:@"\nconnect = "]]];
        [extraServices addObject:@"\n"];
    }
    tpl = [tpl stringByReplacingOccurrencesOfString:@"{Stunnel:ExtraServices}" withString:[extraServices componentsJoinedByString:@"\n"]];
    
    return tpl;
}


- (NSString *)serviceName {
    return @"stunnel";
}


- (NSString *)serviceTitle {
    return @"Stunnel";
}


- (int)proxyPort {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"Stunnel:LocalPort"];
}


- (NSString *)proxySetting {
    return [NSString stringWithFormat:@"PROXY 127.0.0.1:%d", [self proxyPort]];
}


- (void)setupCommandRunner {
    [super setupCommandRunner];
    
    commandRunner.commandPath = @"./stunnel";
    commandRunner.arguments = [NSArray arrayWithObject:@"stunnel.conf"];
}


@end
