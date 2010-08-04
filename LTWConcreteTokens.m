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


@implementation LTWConcreteTokens

-(id)initWithXML:(NSString*)xml {
	static LTWParser *parser = nil;
    static LTWDatabase *sharedDatabase = nil;
	if (!parser) parser = [[LTWParser alloc] init];
    if (!sharedDatabase) sharedDatabase = [[LTWDatabase alloc] init]; // NOTE: If we ever start using the database for things other than LTWConcreteTokens, we'll need to store the shared instance somewhere else.
	
	if (self = [super init]) {
		NSMutableArray *mutableTokens = [[NSMutableArray alloc] init];
		NSMutableArray *mutableTokenExtraInfos = [[NSMutableArray alloc] init];
		text = [xml retain];
		[parser setDocumentText:xml];
		
		NSRange tokenRange;
		NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
		while ((tokenRange = [parser getNextTokenWithExtraInfo:extraInfo]).location != NSNotFound) {
			[mutableTokens addObject:[NSValue valueWithRange:tokenRange]];
			[mutableTokenExtraInfos addObject:[extraInfo copy]];
		}
		
		tokens = mutableTokens;
		tokenExtraInfos = mutableTokenExtraInfos;
		tokenTags = [[NSMutableDictionary alloc] init];
        
        inMemory = YES;
        inDatabase = NO;
        database = [sharedDatabase retain];
        databaseID = 0; // This is set when we saveToDatabase is first called.
        
        allSubTokens = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
    if (!inMemory) [self loadFromDatabase];
	if (index >= [tokens count]) return NSMakeRange(NSNotFound, 0);
	return [[tokens objectAtIndex:index] rangeValue];
}

-(NSDictionary*)extraInfoForTokenAtIndex:(NSUInteger)index {
    if (!inMemory) [self loadFromDatabase];
	if (index >= [tokens count]) return nil;
	return [tokenExtraInfos objectAtIndex:index];
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
	
	NSMutableArray *tags = [tokenTags objectForKey:[NSValue valueWithRange:NSMakeRange(theStartIndex, theEndIndex-theStartIndex+1)]];
	if (!tags) {
		tags = [[NSMutableArray alloc] init];
		[tokenTags setObject:tags forKey:[NSValue valueWithRange:NSMakeRange(theStartIndex, theEndIndex-theStartIndex+1)]];
		[tags release];
	}
	
	[tags addObject:tag];
}

// NOTE: Not sure whether this should be public or whether the caller should have to construct a subrange to query.
// Also, we should probably have a method to return ALL of the tagged ranges in some way that'd be useful to LTWTokensView.
-(NSSet*)_tagsFromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
    if (!inMemory) [self loadFromDatabase];
	NSMutableSet *tags = [NSMutableSet set];
	for (id key in [tokenTags keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop) {
		return (BOOL)([key rangeValue].location <= theStartIndex && NSMaxRange([key rangeValue]) > theEndIndex);
	}]) {
		[tags addObjectsFromArray:[tokenTags objectForKey:key]];
	}
	return tags;
}

-(void)addTag:(LTWTokenTag*)tag {
    if (!inMemory) [self loadFromDatabase];
	[self _addTag:tag fromIndex:0 toIndex:[tokens count]-1];
}

-(NSString*)_text {
    if (!inMemory) [self loadFromDatabase];
	return text;
}

-(void)enumerateTagsWithBlock:(void (^)(NSRange tagTokenRange, LTWTokenTag *tag))block {
    if (!inMemory) [self loadFromDatabase];
    
	[tokenTags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSRange range = [key rangeValue];
		for (LTWTokenTag *tag in obj) {
			block(range, tag);
		}
	}];
}

-(void)saveToDatabase {
    if (!inMemory) return;
    
    for (LTWConcreteSubTokens *subTokens in allSubTokens) {
        [subTokens _becomeIndependentOfSuperTokens];
    }
    
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
    [self enumerateTagsWithBlock:^(NSRange tagTokenRange, LTWTokenTag *tag) {
        [database insertTag:tag fromTokenIndex:tagTokenRange.location toTokenIndex:NSMaxRange(tagTokenRange)-1 tokensID:databaseID]; 
    }];
    
    [tokenExtraInfos enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        [database insertExtraInfo:obj forTokenIndex:index tokensID:databaseID];
    }];
    
    if (NO) { // Remove this if-statement when the LTWDatabase class actually works.
        [text release];
        [tokens release];
        [tokenExtraInfos release];
        [tokenTags release];
        text = nil;
        tokens = nil;
        tokenExtraInfos = nil;
        tokenTags = nil;
        inMemory = NO;
        inDatabase = YES;
    }
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
    tokenExtraInfos = [[NSMutableArray alloc] init];
    for (NSUInteger tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
        NSRange tokenRange = NSMakeRange(NSNotFound, 0);
        [database loadTokenWithRange:&tokenRange index:tokenIndex tokensID:databaseID];
        [tokens addObject:[NSValue valueWithRange:tokenRange]];
        
        NSDictionary *tokenExtraInfo = nil;
        [database loadExtraInfo:&tokenExtraInfo forTokenIndex:tokenIndex tokensID:databaseID];
        [tokenExtraInfos addObject:tokenExtraInfo];
    }
    
    for (NSUInteger tagIndex = 0; tagIndex < numTags; tagIndex++) {
        LTWTokenTag *tag = nil;
        NSUInteger firstTokenIndex = 0, lastTokenIndex = 0;
        [database loadTag:&tag fromTokenIndex:&firstTokenIndex toTokenIndex:&lastTokenIndex tagIndex:tagIndex tokensID:databaseID];
        //[tokenTags addObject:tag]; //?????
    }
    
    // Ideally, we should also restore our subtokens' dependencies here. We could do this by saving the subtokens array to the database as well, but this would involve saving pointers. Perhaps we could just keep the subtokens array in memory. Note that even then we may want to hold a weak reference to the tokens so that they can be deallocated if they're not needed.
    
    inMemory = YES;
}

@end
