//
//  LTWConcreteCopiedTokens.h
//  LTWToolkit
//
//  Created by David Alexander on 10/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWConcreteTokens.h"

@interface LTWConcreteCopiedTokens : LTWConcreteTokens {
    NSUInteger storedStringOffset; // how far into the "real" string (the one that's been paged out to the database) does our string start?
    NSUInteger numCopiedTokens;
}

-(id)initWithSuperTokens:(LTWConcreteTokens*)superTokens forSubTokens:(LTWTokens*)subTokens fromToken:(NSUInteger)startIndex toToken:(NSUInteger)endIndex;

@end
