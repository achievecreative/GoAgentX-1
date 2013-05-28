//
//  GAPACHTTPServer.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAPACHTTPServer.h"

#import "GAPACHTTPConnection.h"
#import "SynthesizeSingleton.h"

@implementation GAPACHTTPServer

SYNTHESIZE_SINGLETON_FOR_CLASS(GAPACHTTPServer, Server)

- (id)init {
    if (self == [super init]) {
        [self setConnectionClass:[GAPACHTTPConnection class]];
        [self setDocumentRoot:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"]];
    }
    
    return self;
}


- (NSString *)pacAddressForProxy {
    int count = 0;
    while (![self isRunning] && count++ < 10000) {
        // do nothing
    }
    int listenPort = [self port] > 0 ? [self port] : [self listeningPort];
    return [NSString stringWithFormat:@"http://127.0.0.1:%d/proxy.pac", listenPort];
}

@end
