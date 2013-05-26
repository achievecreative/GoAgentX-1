//
//  GAPACHTTPServer.h
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "HTTPServer.h"

@interface GAPACHTTPServer : HTTPServer

+ (id)sharedServer;

- (NSString *)pacAddressForProxy;

@end
