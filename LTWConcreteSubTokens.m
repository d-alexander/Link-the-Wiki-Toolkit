//
//  LTWConcreteSubTokens.m
//  LTWToolkit
//
//  Created by David Alexander on 30/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWConcreteSubTokens.h"


@implementation LTWConcreteSubTokens

-(id)initWithTokens:(LTWTokens*)theTokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex propagateTags:(BOOL)shouldPropagateTags {
	if (self = [super init]) {
		superTokens = [theTokens retain];
		startIndex = theStartIndex;
		endIndex = theEndIndex;
		
		propagateTags = shouldPropagateTags;
		tokenTags = shouldPropagateTags ? nil : [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
	if (startIndex + index > endIndex) return NSMakeRange(NSNotFound, 0);
	return [superTokens rangeOfTokenAtIndex:startIndex + index];
}

-(NSDictionary*)extraInfoForTokenAtIndex:(NSUInteger)index {
	if (startIndex + index > endIndex) return nil;
	return [superTokens extraInfoForTokenAtIndex:startIndex + index];
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
		NSMutableArray *tags = [tokenTags objectForKey:[NSValue valueWithRange:NSMakeRange(startIndex, endIndex-startIndex+1)]];
		if (!tags) {
			tags = [[NSMutableArray alloc] init];
			[tokenTags setObject:tags forKey:[NSValue valueWithRange:NSMakeRange(startIndex, endIndex-startIndex+1)]];
			[tags release];
		}
		
		[tags addObject:tag];
	}
}


-(void)addTag:(LTWTokenTag*)tag {
	[self _addTag:tag fromIndex:0 toIndex:(endIndex-startIndex)];
}

-(NSString*)_text {
	return [superTokens _text];
}

#ifndef __COCOTRON__
-(void)enumerateTagsWithBlock:(void (^)(NSRange tagTokenRange, LTWTokenTag *tag))block {
	if (propagateTags) {
		[superTokens enumerateTagsWithBlock:^(NSRange tagTokenRange, LTWTokenTag *tag) {
			if (tagTokenRange.location <= endIndex && NSMaxRange(tagTokenRange) > startIndex) {
				if (tagTokenRange.location < startIndex) {
					tagTokenRange.length -= (startIndex - tagTokenRange.location);
					tagTokenRange.location = startIndex;
				}
				
				if (NSMaxRange(tagTokenRange) >= endIndex) {
					tagTokenRange.length -= (NSMaxRange(tagTokenRange) - endIndex);
				}
				
				// Bring the range into our "token-index-space".
				tagTokenRange.location -= startIndex;
				
				block(tagTokenRange, tag);
			}
		}];
	}else{
		[tokenTags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSRange range = [key rangeValue];
			for (LTWTokenTag *tag in obj) {
				block(range, tag);
			}
		}];
	}
}
#endif

-(NSArray*)tagRanges {
    NSArray *superTokensRanges = [superTokens tagRanges];
    NSMutableArray *tagRanges = [NSMutableArray array];
    
    for (NSValue *value in superTokensRanges) {
        NSRange tagTokenRange = [value rangeValue];
        
        if (tagTokenRange.location <= endIndex && NSMaxRange(tagTokenRange) > startIndex) {
            if (tagTokenRange.location < startIndex) {
                tagTokenRange.length -= (startIndex - tagTokenRange.location);
                tagTokenRange.location = startIndex;
            }
            
            if (NSMaxRange(tagTokenRange) >= endIndex) {
                tagTokenRange.length -= (NSMaxRange(tagTokenRange) - endIndex);
            }
            
            // Bring the range into our "token-index-space".
            tagTokenRange.location -= startIndex;
            
            [tagRanges addObject:[NSValue valueWithRange:tagTokenRange]];
        }
    }
    
    return tagRanges;
}

-(NSArray*)tagsWithRange:(NSRange)range {
    range.location += startIndex;
    return [super tagsWithRange:range];
}

-(void)saveToDatabase {
    [superTokens saveToDatabase];
}

-(void)_becomeIndependentOfSuperTokens {
    
}

@end
