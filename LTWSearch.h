//
//  LTWSearch.h
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LTWTokens.h"

@class LTWSearch;
@protocol LTWSearchRequester

-(NSArray*)handleSearchResult:(LTWTokens*)result forSearch:(LTWSearch*)search;

@end

@interface LTWSearch : NSObject {
    LTWTokens *tokens; // Is this an appropriate way to store a tag-search?
    id <LTWSearchRequester> requester;
}

-(id)initWithTokens:(LTWTokens*)theTokens requester:(id <LTWSearchRequester>)theRequester;
-(id)initWithString:(NSString*)theString requester:(id <LTWSearchRequester>)theRequester;
-(BOOL)tryOnTokenIndex:(NSUInteger)index ofTokens:(LTWTokens*)theTokens newSearches:(NSMutableArray*)newSearches;

@end
