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

-(void)tryOnTokenRange:(LTWTokenRange)range {
    if ([range.tokens matches:tokens fromIndex:range.firstToken toIndex:range.lastToken]) {
        [requester handleSearchResult:[range.tokens tokensFromIndex:range.firstToken toIndex:range.lastToken propagateTags:YES] forSearch:self];
    }
}

@end
