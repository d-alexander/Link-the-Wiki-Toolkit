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


typedef struct LTWTagOccurrence_struct {
    NSUInteger firstToken;
    NSUInteger lastToken;
    LTWTokenTag *tag;
    struct LTWTagOccurrence_struct *next;
} LTWTagOccurrence;

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
    NSMutableArray *allSubTokens; // This is supposed to store all LTWConcreteSubTokens instances that currently have this LTWTokens instance as their superTokens. Before saving ourself to the database, we tell all our subtokens to "become independent" of us, which means that they create their own LTWConcreteTokens instance which holds only the tokens they need, and use it as their superTokens. (NOTE: I'm not sure what we should do if *that* instance needs to be saved to the database!) Ideally, we'd like to be able to tell them later (once we're back in memory) to re-parent themselves to us.
}

-(id)initWithXML:(NSString*)xml;
-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index;

-(LTWTokens*)tokensFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex propagateTags:(BOOL)shouldPropagateTags;
-(BOOL)matches:(LTWTokens*)tokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex;
-(BOOL)matches:(LTWTokens*)theTokens fromIndex:(NSUInteger)theStartIndex;

-(void)addTag:(LTWTokenTag*)tag;
-(void)_addTag:(LTWTokenTag*)tag fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex;

// NOTE: This should really return an array of occurrences, but currently it just returns an array of tags.
-(NSArray*)tagsStartingAtTokenIndex:(NSUInteger)firstToken;
-(NSArray*)_tagsStartingAtTokenIndex:(NSUInteger)firstToken occurrence:(LTWTagOccurrence**)occurrence;
-(LTWTokenTag*)tagWithName:(NSString*)name startingAtTokenIndex:(NSUInteger)firstToken;

-(void)subtokensWillDeallocate:(LTWTokens*)subTokens;

-(NSUInteger)count;

-(void)saveToDatabase;

-(NSString*)_text;

-(NSString*)stringValue;

@end
