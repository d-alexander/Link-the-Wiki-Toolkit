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
        
        firstCopiedToken = startIndex;
        numCopiedTokens = endIndex - startIndex + 1;
        
        // NOTE: Should really copy rather than retaining
        tokens = [superTokens->tokens retain];
        tagOccurrences = [superTokens->tagOccurrences retain];
        
        [allSubTokens addObject:[NSValue valueWithNonretainedObject:subTokens]];
        
        NSUInteger rangeStart = [superTokens rangeOfTokenAtIndex:startIndex].location;
        NSRange lastTokenRange = [superTokens rangeOfTokenAtIndex:endIndex];
        
        for (LTWTokenTag *tag in [superTokens tagsStartingAtTokenIndex:startIndex]) {
            if ([[tag tagName] isEqual:@"tagStartOffset"]) rangeStart -= [[tag tagValue] intValue];
        }
        for (LTWTokenTag *tag in [superTokens tagsStartingAtTokenIndex:endIndex]) {
            if ([[tag tagName] isEqual:@"tagStartOffset"]) lastTokenRange.location -= [[tag tagValue] intValue];
            if ([[tag tagName] isEqual:@"tagLength"]) lastTokenRange.length = [[tag tagValue] intValue];
        }
        
        NSUInteger rangeEnd = NSMaxRange(lastTokenRange);
        
        if ((NSInteger)rangeStart < 0) {
            NSLog(@"Trying to create token with negative range-start!");
        }
        
        text = [[superTokens->text substringWithRange:NSMakeRange(rangeStart, rangeEnd-rangeStart)] retain];
        
        storedStringOffset = rangeStart;
        
        inMemory = YES;
        inDatabase = NO;
        
        database = [[LTWDatabase sharedInstance] retain];
        databaseID = 0;
    }
    return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
    if (!inMemory) [self loadFromDatabase];
    index += firstCopiedToken;
	if (index >= [tokens count]) return NSMakeRange(NSNotFound, 0);
    NSRange range = [[tokens objectAtIndex:index] rangeValue];
	range.location -= storedStringOffset;
    
    if ((NSInteger)range.location < 0) {
        NSLog(@"Trying to return token with negative range-start!");
    }
    
    return range;
}

-(NSArray*)_tagsStartingAtTokenIndex:(NSUInteger)firstToken occurrence:(LTWTagOccurrence**)occurrencePtr {
    return [super _tagsStartingAtTokenIndex:firstToken+firstCopiedToken occurrence:occurrencePtr];
}

-(NSUInteger)count {
    return numCopiedTokens;
}

@end
