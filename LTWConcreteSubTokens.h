//
//  LTWConcreteSubTokens.h
//  LTWToolkit
//
//  Created by David Alexander on 30/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWTokens.h"

@interface LTWConcreteSubTokens : LTWTokens {
	LTWTokens *superTokens;
	NSUInteger startIndex;
	NSUInteger endIndex;
	BOOL propagateTags;
	
	NSMutableDictionary *tokenTags; // maps NSRanges of token indices onto NSArrays of LTWTokenTags.
}

-(id)initWithTokens:(LTWTokens*)theTokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex propagateTags:(BOOL)shouldPropagateTags;

-(void)_becomeIndependentOfSuperTokens;

@end
