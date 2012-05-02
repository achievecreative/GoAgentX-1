//
//  GAPACHTTPConnection.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAPACHTTPConnection.h"

#import "HTTPDynamicFileResponse.h"

@implementation GAPACHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	NSString *filePath = [self filePathForURI:path];
	
	// Convert to relative path
	
	NSString *documentRoot = [config documentRoot];
	
	if (![filePath hasPrefix:documentRoot]) {
		// Uh oh.
		// HTTPConnection's filePathForURI was supposed to take care of this for us.
		return nil;
	}
	
	NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    
	if ([relativePath isEqualToString:@"/proxy.pac"]) {
        NSString *pacTemplate = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pactemplate" ofType:@"pac"] encoding:NSUTF8StringEncoding error:NULL];
        pacTemplate = [[NSString alloc] initWithData:[NSData dataFromBase64String:pacTemplate] encoding:NSUTF8StringEncoding];
        
        NSString *query = [path substringFromIndex:[@"/proxy.pac?" length]];
        query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        query = [query stringByReplacingOccurrencesOfString:@"/" withString:@" "];
        
        NSString *pacContent = [pacTemplate stringByReplacingOccurrencesOfString:@"PROXY 127.0.0.1:65536" withString:query];
        
        NSMutableDictionary *replacementDict = [NSMutableDictionary dictionaryWithObject:pacContent forKey:@"PAC_CONTENT"];
		
		return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                   forConnection:self
                                                       separator:@"%%"
                                           replacementDictionary:replacementDict];
	}
	
	return [super httpResponseForMethod:method URI:path];
}

@end
