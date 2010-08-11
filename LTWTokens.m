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

-(id)init {
    if (self = [super init]) {
        allSubTokens = [[NSMutableArray alloc] init];
    }
    return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
	return NSMakeRange(NSNotFound, 0);
}

-(NSUInteger)count {
    return 0;
}

-(LTWTokens*)tokensFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex propagateTags:(BOOL)shouldPropagateTags {
	LTWConcreteSubTokens *subTokens = [[[LTWConcreteSubTokens alloc] initWithTokens:self fromIndex:startIndex toIndex:endIndex propagateTags:shouldPropagateTags] autorelease];
    [allSubTokens addObject:[NSValue valueWithNonretainedObject:subTokens]];
    return subTokens;
}

-(void)subtokensWillDeallocate:(LTWTokens*)subTokens {
    [allSubTokens removeObject:[NSValue valueWithNonretainedObject:subTokens]];
}

-(BOOL)matches:(LTWTokens*)tokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
    return NO;
}

-(BOOL)matches:(LTWTokens*)theTokens fromIndex:(NSUInteger)theStartIndex {
    return [self matches:theTokens fromIndex:theStartIndex toIndex:theStartIndex+[theTokens count]-1];
}

-(void)_addTag:(LTWTokenTag*)tag fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {

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

-(void)saveToDatabase {
    
}

-(NSString*)stringValue {
    NSMutableString *string = [NSMutableString string];
    NSString *text = [self _text];
    for (NSValue *range in self) {
        [string appendFormat:@" %@", [text substringWithRange:[range rangeValue]]];
    }
    return string;
}

-(NSArray*)tagsStartingAtTokenIndex:(NSUInteger)firstToken {
    return [self _tagsStartingAtTokenIndex:firstToken occurrence:NULL];
}

-(NSArray*)_tagsStartingAtTokenIndex:(NSUInteger)firstToken occurrence:(LTWTagOccurrence**)occurrence {
    return nil;
}

-(LTWTokenTag*)tagWithName:(NSString*)name startingAtTokenIndex:(NSUInteger)firstToken {
    for (LTWTokenTag *tag in [self tagsStartingAtTokenIndex:firstToken]) {
        if ([[tag tagName] isEqual:name]) return tag;
    }
    return nil;
}

-(void)dealloc{
    NSLog(@"%@ deallocated", [self class]); // might not be safe to try to log the description of the object itself!
    [super dealloc];
}


@end