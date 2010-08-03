//
//  LTWSearch.m
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWSearch.h"


@implementation LTWSearch

-(id)initWithTokens:(LTWTokens*)theTokens requester:(id <LTWSearchRequester>)theRequester {
    if (self = [super init]) {
        tokens = [theTokens retain];
        requester = theRequester;
    }
    return self;
}

-(id)initWithString:(NSString*)theString requester:(id <LTWSearchRequester>)theRequester {
    LTWTokens *theTokens = [[LTWTokens alloc] initWithXML:theString];
    self = [self initWithTokens:theTokens requester:theRequester];
    [theTokens release];
    requester = theRequester;
    return self;
}

-(BOOL)tryOnTokenIndex:(NSUInteger)index ofTokens:(LTWTokens*)theTokens newSearches:(NSMutableArray*)newSearches {
    if ([theTokens matches:tokens fromIndex:index toIndex:index+[tokens count]-1]) {
        if (requester) {
            NSArray *searches = [requester handleSearchResult:[theTokens tokensFromIndex:index toIndex:index+[tokens count]-1 propagateTags:YES] forSearch:self];
            if (searches) {
                [newSearches addObjectsFromArray:searches];
            }
        }
        // Should actually only be returning YES if the requester either tags some tokens or starts some new searches.
        return YES;
    }else{
        return NO;
    }
}

@end
