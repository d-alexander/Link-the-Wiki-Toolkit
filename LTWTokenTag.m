//
//  LTWTokenTag.m
//  LTWToolkit
//
//  Created by David Alexander on 1/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWTokenTag.h"


@implementation LTWTokenTag

-(id)initWithName:(NSString*)theName value:(id)theValue {
	[theName retain];
	[theValue retain];
	
	name = theName;
	value = theValue;
	
	return self;
}

-(void)dealloc {
	[name release];
	[value release];
	[super dealloc];
}

-(BOOL)isEqual:(id)object {
	return [object isKindOfClass:[LTWTokenTag class]] && [name isEqual:((LTWTokenTag*)object)->name] && [value isEqual:((LTWTokenTag*)object)->value];
}

-(NSUInteger)hash {
	// NOTE: If article references are added, the hash method must be modified so that an article reference has the same hash whether resolved or unresolved.
	return [name hash] + [value hash];
}

-(NSString*)tagName {
	return name;
}

-(id)tagValue {
	return value;
}

@end
