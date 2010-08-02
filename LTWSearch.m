//
//  LTWSearch.m
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWSearch.h"


@implementation LTWSearch

-(id)initWithTokens:(LTWTokens*)theTokens {
    if (self = [super init]) {
        tokens = [theTokens retain];
    }
    return self;
}

-(id)initWithString:(NSString*)theString {
    LTWTokens *theTokens = [[LTWTokens alloc] initWithXML:theString];
    self = [self initWithTokens:theTokens];
    [theTokens release];
    return self;
}

-(BOOL)tryOnTokenIndex:(NSUInteger)index ofTokens:(LTWTokens*)theTokens newSearches:(NSMutableArray*)newSearches {
    if ([theTokens matches:tokens fromIndex:index toIndex:index+[tokens count]-1]) {
        NSArray *searches = [requester handleSearchResult:[theTokens tokensFromIndex:index toIndex:index+[tokens count]-1 propagateTags:YES] forSearch:self];
        [newSearches addObjectsFromArray:searches];
        return YES;
    }else{
        return NO;
    }
}

@end
