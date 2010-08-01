//
//  LTWConcreteTokens.h
//  LTWToolkit
//
//  Created by David Alexander on 30/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWTokens.h"

@interface LTWConcreteTokens : LTWTokens {
	NSString *text;
	NSArray *tokens;
	NSArray *tokenExtraInfos; // NOTE: Currently, these extraInfo dictionaries are used to get the attributes for a given token. It would be really nice if we could find a nicer way of doing this, since the current approach introduces a lot of coupling. Also, it's not going to be a very efficient way to store large numbers of tokens!
	NSMutableDictionary *tokenTags; // maps NSRanges of token indices onto NSArrays of LTWTokenTags.
}

@end
