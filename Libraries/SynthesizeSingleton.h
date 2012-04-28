//
//  SynthesizeSingleton.h
//  CocoaWithLove
//
//  Created by Matt Gallagher on 20/10/08.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname, name) \
 \
static classname *shared##name = nil; \
 \
+ (classname *)shared##name \
{ \
	@synchronized(self) \
	{ \
		if (shared##name == nil) \
		{ \
			shared##name = [[self alloc] init]; \
		} \
	} \
	 \
	return shared##name; \
} \
 \
+ (id)allocWithZone:(NSZone *)zone \
{ \
	@synchronized(self) \
	{ \
		if (shared##name == nil) \
		{ \
			shared##name = [super allocWithZone:zone]; \
			return shared##name; \
		} \
	} \
	 \
	return nil; \
} \
 \
- (id)copyWithZone:(NSZone *)zone \
{ \
	return self; \
} \
 \
