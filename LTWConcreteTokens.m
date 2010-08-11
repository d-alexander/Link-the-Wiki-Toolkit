//
//  LTWConcreteTokens.m
//  LTWToolkit
//
//  Created by David Alexander on 30/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWConcreteTokens.h"

#import "LTWParser.h"
#import "LTWConcreteSubTokens.h"
#import "LTWConcreteCopiedTokens.h"

@implementation LTWConcreteTokens

-(id)initWithXML:(NSString*)xml {
	static LTWParser *parser = nil;
    static LTWDatabase *sharedDatabase = nil;
	if (!parser) parser = [[LTWParser alloc] init];
    if (!sharedDatabase) sharedDatabase = [[LTWDatabase alloc] init]; // NOTE: If we ever start using the database for things other than LTWConcreteTokens, we'll need to store the shared instance somewhere else.
	
	if (self = [super init]) {
		NSMutableArray *mutableTokens = [[NSMutableArray alloc] init];
		text = [xml retain];
		[parser setDocumentText:xml];
        
        // We have to allocate this before parsing, because as we parse we'll get "tags" from the extraInfo of each token.
		tagOccurrences = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsOpaqueMemory];
		
		NSRange tokenRange;
		NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
        NSUInteger tokenIndex = 0;
		while ((tokenRange = [parser getNextTokenWithExtraInfo:extraInfo]).location != NSNotFound) {
			[mutableTokens addObject:[NSValue valueWithRange:tokenRange]];
            
            LTWTagOccurrence *occurrenceList = NULL;
            
            for (NSString *key in [extraInfo allKeys]) {
                LTWTagOccurrence *occurrence = malloc(sizeof *occurrence);
                occurrence->firstToken = tokenIndex;
                occurrence->lastToken = tokenIndex;
                occurrence->tag = [[LTWTokenTag alloc] initWithName:key value:[extraInfo valueForKey:key]];
                occurrence->next = occurrenceList;
                
                occurrenceList = occurrence;
            }
            
            [tagOccurrences addPointer:occurrenceList];
            
            tokenIndex++;
		}
		
		tokens = mutableTokens;
        
        inMemory = YES;
        inDatabase = NO;
        database = [sharedDatabase retain];
        databaseID = 0; // This is set when we saveToDatabase is first called.
	}
	
	return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
    if (!inMemory) [self loadFromDatabase];
	if (index >= [tokens count]) return NSMakeRange(NSNotFound, 0);
	return [[tokens objectAtIndex:index] rangeValue];
}

// Why do we even need an end-index? We'll (almost?) always be comparing part of self against the entirety of theTokens.
-(BOOL)matches:(LTWTokens*)theTokens fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
    if (!inMemory) [self loadFromDatabase];
    for (NSUInteger currentIndex = theStartIndex; currentIndex <= theEndIndex; currentIndex++) {
        NSRange charRange = [self rangeOfTokenAtIndex:currentIndex];
        NSRange otherCharRange = [theTokens rangeOfTokenAtIndex:currentIndex-theStartIndex];
        NSString *temp = [[theTokens _text] substringWithRange:otherCharRange];
        if ([text compare:temp options:NSCaseInsensitiveSearch range:charRange] != NSOrderedSame) {
            return NO;
        }
    }
    return YES;
}

-(NSUInteger)count {
    if (!inMemory) [self loadFromDatabase];
    return [tokens count];
}

// This method is private because tags should always be added to an entire range. Tags can then be propagated up to the superranges of that range.
-(void)_addTag:(LTWTokenTag*)tag fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
    if (!inMemory) [self loadFromDatabase];
    
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LTWTokenTagsChangedNotification object:self]];
    
    LTWTagOccurrence *occurrence = malloc(sizeof *occurrence);
    occurrence->firstToken = theStartIndex;
    occurrence->lastToken = theEndIndex;
    occurrence->tag = [tag retain];
    occurrence->next = [tagOccurrences pointerAtIndex:theStartIndex];
    
    [tagOccurrences replacePointerAtIndex:theStartIndex withPointer:occurrence];
}

-(void)addTag:(LTWTokenTag*)tag {
    if (!inMemory) [self loadFromDatabase];
	[self _addTag:tag fromIndex:0 toIndex:[tokens count]-1];
}

-(NSArray*)_tagsStartingAtTokenIndex:(NSUInteger)firstToken occurrence:(LTWTagOccurrence**)occurrencePtr {
    NSMutableArray *array = [NSMutableArray array];
    LTWTagOccurrence *occurrence;
    for (occurrence = [tagOccurrences pointerAtIndex:firstToken]; occurrence != NULL; occurrence = occurrence->next) {
        [array addObject:occurrence->tag];
    }
    if (occurrencePtr) *occurrencePtr = occurrence;
    return array;
}

-(NSString*)_text {
    if (!inMemory) [self loadFromDatabase];
	return text;
}

-(void)removeSuperTokenDependenciesForTokens:(LTWTokens*)theTokens {
    NSArray *allSubTokensCopy = [theTokens->allSubTokens copy];
    for (NSValue *value in allSubTokensCopy) {
        LTWConcreteSubTokens *subTokens = [value nonretainedObjectValue];
        if ([theTokens isKindOfClass:[LTWConcreteCopiedTokens class]]) {
            [self removeSuperTokenDependenciesForTokens:subTokens];
        }else{
            [subTokens _becomeIndependentOfSuperTokens];
        }
    }
    [allSubTokensCopy release];
}

-(void)saveToDatabase {
    if (!inMemory) return;
    
    [self removeSuperTokenDependenciesForTokens:self];
    
    [database beginTransaction];
    
    if (!inDatabase) {
        databaseID = [database insertTokensWithText:[self _text]];
        NSUInteger index = 0;
        for (NSValue *value in self) {
            [database insertTokenWithRange:[value rangeValue] index:index tokensID:databaseID];
            index++;
        }
    }
    
    // NOTE: The insertTag method will somehow have to know when a tag already exists so as not to replace it.
    // (Should tags be immutable once added?)
    
    NSUInteger tagIndex = 0;
    for (NSUInteger tokenIndex = 0; tokenIndex < [tokens count]; tokenIndex++) {
        for (LTWTagOccurrence *occurrence = [tagOccurrences pointerAtIndex:tokenIndex]; occurrence != NULL; occurrence = occurrence->next) {
            [database insertTag:occurrence->tag withIndex:tagIndex fromTokenIndex:occurrence->firstToken toTokenIndex:occurrence->lastToken tokensID:databaseID];
            tagIndex++;
        }
    }
    
    [database commit]; // Should check the result before releasing the memory.
    
    [text release];
    [tokens release];
    
    // NOTE: Not freeing here because tagOccurrences is not guaranteed not to have been retained by something else!
    /*
    for (NSUInteger tokenIndex = 0; tokenIndex < [tagOccurrences count]; tokenIndex++) {
        LTWTagOccurrence *occurrence = [tagOccurrences pointerAtIndex:tokenIndex];
        while (occurrence != NULL) {
            LTWTagOccurrence *prevOccurrence = occurrence;
            occurrence = occurrence->next;
            [prevOccurrence->tag release];
            free(prevOccurrence);
        }
    }
     */
    [tagOccurrences release];
    
    text = nil;
    tokens = nil;
    tagOccurrences  = nil;
    
    inMemory = NO;
    inDatabase = YES;
}

-(void)loadFromDatabase {
    if (inMemory) return;
    if (!inDatabase) {
        NSLog(@"ERROR: %@ isn't in memory but also isn't in database!", self);
        return;
    }
    
    NSUInteger numTokens = 0, numTags = 0;
    [database loadTokensWithText:&text numTokens:&numTokens numTags:&numTags tokensID:databaseID];
    
    tokens = [[NSMutableArray alloc] init];
    for (NSUInteger tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
        NSRange tokenRange = NSMakeRange(NSNotFound, 0);
        [database loadTokenWithRange:&tokenRange index:tokenIndex tokensID:databaseID];
        [tokens addObject:[NSValue valueWithRange:tokenRange]];
    }
    
    tagOccurrences = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsOpaqueMemory];
    [tagOccurrences setCount:numTokens];
    for (NSUInteger tagIndex = 0; tagIndex < numTags; tagIndex++) {
        LTWTokenTag *tag = nil;
        NSUInteger firstTokenIndex = 0, lastTokenIndex = 0;
        [database loadTag:&tag fromTokenIndex:&firstTokenIndex toTokenIndex:&lastTokenIndex tagIndex:tagIndex tokensID:databaseID];
        
        LTWTagOccurrence *occurrence = malloc(sizeof *occurrence);
        occurrence->firstToken = firstTokenIndex;
        occurrence->lastToken = lastTokenIndex;
        occurrence->tag = [tag retain];
        occurrence->next = [tagOccurrences pointerAtIndex:firstTokenIndex];
        
        [tagOccurrences replacePointerAtIndex:firstTokenIndex withPointer:occurrence];
    }
    
    // Ideally, we should also restore our subtokens' dependencies here. We could do this by saving the subtokens array to the database as well, but this would involve saving pointers. Perhaps we could just keep the subtokens array in memory. Note that even then we may want to hold a weak reference to the tokens so that they can be deallocated if they're not needed.
    
    inMemory = YES;
}

@end
