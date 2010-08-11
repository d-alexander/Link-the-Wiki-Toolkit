//
//  LTWConcreteCopiedTokens.m
//  LTWToolkit
//
//  Created by David Alexander on 10/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWConcreteCopiedTokens.h"


@implementation LTWConcreteCopiedTokens

-(id)initWithSuperTokens:(LTWConcreteTokens*)superTokens forSubTokens:(LTWTokens*)subTokens fromToken:(NSUInteger)startIndex toToken:(NSUInteger)endIndex {
    if (self = [super init]) { // note: not initWithXML:
        
        numCopiedTokens = endIndex - startIndex + 1;
        
        // NOTE: Should really copy rather than retaining
        tokens = [superTokens->tokens retain];
        tagOccurrences = [superTokens->tagOccurrences retain];
        
        [allSubTokens addObject:[NSValue valueWithNonretainedObject:subTokens]];
        
        NSUInteger rangeStart = [superTokens rangeOfTokenAtIndex:startIndex].location;
        NSUInteger rangeEnd = NSMaxRange([superTokens rangeOfTokenAtIndex:endIndex]);
        
        // TODO: EXPAND RANGE TO COVER XML TAGS. (Use the tagRange tag.)
        // (Note: tagRange will be stored as a string!)
        
        text = [[superTokens->text substringWithRange:NSMakeRange(rangeStart, rangeEnd-rangeStart)] retain];
        
        storedStringOffset = rangeStart;
        
        inMemory = YES;
        inDatabase = NO;
        
        // NOTE: This isn't strictly required YET since the database will never get refcount 0 anyway, but it really should be fixed.
        //database = [sharedDatabase retain];
        databaseID = 0;
    }
    return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
    if (!inMemory) [self loadFromDatabase];
	if (index >= [tokens count]) return NSMakeRange(NSNotFound, 0);
    NSRange range = [[tokens objectAtIndex:index] rangeValue];
	range.location -= storedStringOffset;
    return range;
}

-(NSUInteger)count {
    return numCopiedTokens;
}

@end
