//
//  LTWTokens.h
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWTokenTag.h"

extern NSString *LTWTokenTagsChangedNotification;

@class LTWTokens;
typedef struct {
    LTWTokens *tokens;
    NSUInteger firstToken;
    NSUInteger lastToken;
} LTWTokenRange;

/*
 This is the abstract base class of a class cluster that handles the storage of sequences of tagged tokens.
 In a sequence of tokens, the tokens themselves are immutable but the tags are mutable. However, when creating a subsequence of a given sequence, the caller can choose whether or not tags should be inherited from the supersequence (and whether tags added to the subsequence should be propagated up to the supersequence).
 A common use-case of subsequences is to specify a range over which a tag is to be added. To do this, the caller acquires the appropriate subsequence (with token-propagation enabled), adds the tag by sending a message to the newly-created subsequence, and then releases the subsequence. The supersequence now has the tag, but only over the appropriate range.
 */
@interface LTWTokens : NSObject <NSFastEnumeration> {
    
}

-(id)initWithXML:(NSString*)xml;
-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index;
-(NSDictionary*)extraInfoForTokenAtIndex:(NSUInteger)index;



-(LTWTokens*)tokensFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex propagateTags:(BOOL)shouldPropagateTags;
-(BOOL)matches:(LTWTokens*)tokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex;

-(void)addTag:(LTWTokenTag*)tag;
-(void)_addTag:(LTWTokenTag*)tag fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex;
-(NSSet*)_tagsFromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex;

-(void)enumerateTagsWithBlock:(void (^)(NSRange tagTokenRange, LTWTokenTag *tag))block;
-(NSUInteger)count;

-(void)saveToDatabase;

-(NSString*)_text;

@end
