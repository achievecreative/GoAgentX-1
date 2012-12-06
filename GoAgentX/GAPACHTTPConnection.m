//
//  GAPACHTTPConnection.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAPACHTTPConnection.h"

#import "HTTPDynamicFileResponse.h"
#import "NSData+Base64.h"
#import "HTTPFileResponse.h"

@implementation GAPACHTTPConnection

- (NSString *)customPACDomainList {
    NSData *domainListData = [[NSUserDefaults standardUserDefaults] dataForKey:@"GoAgentX:CustomPACDomainList"];
    NSString *customDomainListString = domainListData ? [(NSAttributedString *)[NSUnarchiver unarchiveObjectWithData:domainListData] string] : @"";
    customDomainListString = [customDomainListString stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    customDomainListString = [customDomainListString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray *customDomainList = [customDomainListString componentsSeparatedByString:@"\n"];
    
    NSMutableArray *ret = [NSMutableArray new];
    for (NSString *line in customDomainList) {
        if ([line length] > 0) {
            [ret addObject:line];
        }
    }
    
    if ([ret count] > 0) {
        return [NSString stringWithFormat:@"|| shExpMatch(host, \"%@\")", [ret componentsJoinedByString:@"\")\n\t|| shExpMatch(host, \""]];
    }
    
    return @"";
}


- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    BOOL usePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:AutoToggleSystemProxyWithPAC"];
    BOOL useCustomePAC = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoAgent:UseCustomPACAddress"];
    NSString *customPAC = [[NSUserDefaults standardUserDefaults] stringForKey:@"GoAgent:CustomPACAddress"];
    
    if (usePAC && useCustomePAC && customPAC.length > 0) {
        NSString *filePath = [[NSURL URLWithString:customPAC] path];
        return [[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:self];
    }
    
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
        pacContent = [pacContent stringByReplacingOccurrencesOfString:@"${GoAgentX:CustomPACDomainList}"
                                                           withString:[self customPACDomainList]];
        
        NSMutableDictionary *replacementDict = [NSMutableDictionary dictionaryWithObject:pacContent forKey:@"PAC_CONTENT"];
		
		return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                   forConnection:self
                                                       separator:@"%%"
                                           replacementDictionary:replacementDict];
	}
	
	return [super httpResponseForMethod:method URI:path];
}

@end
