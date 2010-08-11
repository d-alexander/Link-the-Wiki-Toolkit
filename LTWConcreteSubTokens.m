//
//  LTWConcreteSubTokens.m
//  LTWToolkit
//
//  Created by David Alexander on 30/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWConcreteSubTokens.h"
#import "LTWConcreteCopiedTokens.h"


@implementation LTWConcreteSubTokens

-(id)initWithTokens:(LTWTokens*)theTokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex propagateTags:(BOOL)shouldPropagateTags {
	if (self = [super init]) {
		superTokens = [theTokens retain];
		startIndex = theStartIndex;
		endIndex = theEndIndex;
		
		propagateTags = shouldPropagateTags;
	}
	return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
	if (startIndex + index > endIndex) return NSMakeRange(NSNotFound, 0);
	return [superTokens rangeOfTokenAtIndex:startIndex + index];
}

-(BOOL)matches:(LTWTokens*)theTokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
    return [superTokens matches:theTokens fromIndex:startIndex+theStartIndex toIndex:startIndex+theEndIndex];
}

-(NSUInteger)count {
    return endIndex - startIndex + 1;
}

// This method is private because tags should always be added to an entire range. Tags can then be propagated up to the superranges of that range.
-(void)_addTag:(LTWTokenTag*)tag fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LTWTokenTagsChangedNotification object:self]];
	
	if (propagateTags) {
		[superTokens _addTag:tag fromIndex:startIndex+theStartIndex toIndex:startIndex+theEndIndex];
	}else{
		// Not yet implemented.
	}
}


-(void)addTag:(LTWTokenTag*)tag {
	[self _addTag:tag fromIndex:0 toIndex:(endIndex-startIndex)];
}

-(NSString*)_text {
	return [superTokens _text];
}

-(NSArray*)_tagsStartingAtTokenIndex:(NSUInteger)firstToken occurrence:(LTWTagOccurrence**)occurrencePtr {
    return [superTokens _tagsStartingAtTokenIndex:startIndex+firstToken occurrence:occurrencePtr];
}

-(void)saveToDatabase {
    [superTokens saveToDatabase];
}

-(void)_becomeIndependentOfSuperTokens {
    LTWTokens *currentAncestor = superTokens;
    NSUInteger startIndexInAncestor = startIndex, endIndexInAncestor = endIndex;
    while (![currentAncestor isKindOfClass:[LTWConcreteTokens class]]) {
        startIndexInAncestor += ((LTWConcreteSubTokens*)currentAncestor)->startIndex;
        endIndexInAncestor += ((LTWConcreteSubTokens*)currentAncestor)->startIndex;
        currentAncestor = ((LTWConcreteSubTokens*)currentAncestor)->superTokens;
    }
    
    LTWConcreteTokens *root = (LTWConcreteTokens*)currentAncestor;
    
    LTWTokens *oldSupertokens = superTokens;
    superTokens = [[LTWConcreteCopiedTokens alloc] initWithSuperTokens:root forSubTokens:self fromToken:startIndexInAncestor toToken:endIndexInAncestor];
    [oldSupertokens subtokensWillDeallocate:self];
    [oldSupertokens release];
}

-(void)dealloc {
    if ([allSubTokens count] > 0) {
        NSLog(@"Tried to dealloc %@ while it still had subtokens!", self);
    }
    [superTokens subtokensWillDeallocate:self];
    [superTokens release];
    [super dealloc];
}

@end
