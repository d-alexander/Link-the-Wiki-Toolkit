//
//  LTWTokens.m
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWTokens.h"

#import "LTWConcreteTokens.h"
#import "LTWConcreteSubTokens.h"

@implementation LTWTokens

NSString *LTWTokenTagsChangedNotification = @"LTWTokenTagsChangedNotification";

+(id)alloc {
    if ([self isEqual:[LTWTokens class]]) {
        return [LTWConcreteTokens alloc];
    }else{
        return [super alloc];
	}
}

+(id)allocWithZone:(NSZone*)zone {
    if ([self isEqual:[LTWTokens class]]) {
        return [LTWConcreteTokens allocWithZone:zone];
    }else{
        return [super allocWithZone:zone];
	}
}

-(id)initWithXML:(NSString*)xml {
	return nil;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
	return NSMakeRange(NSNotFound, 0);
}

-(NSDictionary*)extraInfoForTokenAtIndex:(NSUInteger)index {
	return nil;
}

-(NSUInteger)count {
    return 0;
}

-(LTWTokens*)tokensFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex propagateTags:(BOOL)shouldPropagateTags {
	return [[[LTWConcreteSubTokens alloc] initWithTokens:self fromIndex:startIndex toIndex:endIndex propagateTags:shouldPropagateTags] autorelease];
}

-(BOOL)matches:(LTWTokens*)tokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
    return NO;
}

-(void)_addTag:(LTWTokenTag*)tag fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {

}

// NOTE: Not sure whether this should be public or whether the caller should have to construct a subrange to query.
// Also, we should probably have a method to return ALL of the tagged ranges in some way that'd be useful to LTWTokensView.
-(NSSet*)_tagsFromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
	return nil;
}

-(void)addTag:(LTWTokenTag*)tag {

}

-(NSString*)_text {
	return nil;
}

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id*)stackbuf count:(NSUInteger)len {
    state->itemsPtr = stackbuf;
    state->mutationsPtr = (unsigned long*)self;
    for (NSUInteger i = 0; i < len; i++) {
        if (state->state >= [self count]) return i;
        stackbuf[i] = [[NSValue valueWithRange:[self rangeOfTokenAtIndex:state->state]] retain];
        state->state++;
    }
    return len;
}
                                           
-(void)enumerateTagsWithBlock:(void (^)(NSRange tagTokenRange, LTWTokenTag *tag))block {
	
}

-(void)saveToDatabase {
    
}

@end