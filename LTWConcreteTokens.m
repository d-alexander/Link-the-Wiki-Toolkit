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
	if (!parser) parser = [[LTWParser alloc] init];
	
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
	}
	
	return self;
}

-(NSRange)rangeOfTokenAtIndex:(NSUInteger)index {
	if (index >= [tokens count]) return NSMakeRange(NSNotFound, 0);
	return [[tokens objectAtIndex:index] rangeValue];
}

-(NSDictionary*)extraInfoForTokenAtIndex:(NSUInteger)index {
	if (index >= [tokens count]) return nil;
	return [tokenExtraInfos objectAtIndex:index];
}

-(LTWTokens*)tokensFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex propagateTags:(BOOL)shouldPropagateTags {
	return [[[LTWConcreteSubTokens alloc] initWithTokens:self fromIndex:startIndex toIndex:endIndex propagateTags:shouldPropagateTags] autorelease];
}

// This method is private because tags should always be added to an entire range. Tags can then be propagated up to the superranges of that range.
-(void)_addTag:(LTWTokenTag*)tag fromIndex:(NSUInteger)theStartIndex toIndex:(NSUInteger)theEndIndex {
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
	NSMutableSet *tags = [NSMutableSet set];
	for (id key in [tokenTags keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop) {
		return (BOOL)([key rangeValue].location <= theStartIndex && NSMaxRange([key rangeValue]) > theEndIndex);
	}]) {
		[tags addObjectsFromArray:[tokenTags objectForKey:key]];
	}
	return tags;
}

-(void)addTag:(LTWTokenTag*)tag {
	[self _addTag:tag fromIndex:0 toIndex:[tokens count]-1];
}

-(NSString*)_text {
	return text;
}

-(void)enumerateTagsWithBlock:(void (^)(NSRange tagTokenRange, LTWTokenTag *tag))block {
	[tokenTags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSRange range = [key rangeValue];
		for (LTWTokenTag *tag in obj) {
			block(range, tag);
		}
	}];
}

@end
