//
//  LTWTokenTag.h
//  LTWToolkit
//
//  Created by David Alexander on 1/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 LTWTokenTags are immutable name/value pairs that can be attached to tokens or ranges of tokens within an LTWTokens instance.
 Hash-consing is used to make sure that every occurrence of a given name/value pair points to the name LTWTokenTag instance.
 (Note: This could be tricky to keep up if multi-threading is added later.)
 LTWTokenTag values could be things like strings, numbers, references to articles, or references for where to find (e.g. download) articles which would then become references to articles. (The latter transition being an example of LTWTokenTags not being strictly immutable, although semantically they would behave as if they were.)
 LTWTokens instances may choose whether or not their LTWTokenTag instances should be propagated up and down the hierarchy of LTWTokens instances.
 IDEA: Maybe at some point tag-names could be hashed so that searches didn't have to compare tag-names expensively.
 */
@interface LTWTokenTag : NSObject {
	NSString *name;
	id value;
}

-(id)initWithName:(NSString*)theName value:(id)theValue;
-(NSString*)tagName;
-(id)tagValue;

@end
