//
//  LTWGUIRepresentedObjects.m
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIRepresentedObjects.h"

@implementation LTWGUILink

@synthesize anchor;
@synthesize target;
@synthesize isRelevant;

-(NSArray*)displayableProperties {
    return [NSArray arrayWithObjects:@"anchor", @"target", @"isRelevant", nil];
}
/*
-(NSArray*)propertyHierarchy {
    return [NSArray arrayWithObjects:@"target", nil];
}
*/
@end

@implementation LTWGUIArticle

@synthesize article;

-(NSArray*)displayableProperties {
    return [NSArray arrayWithObjects:@"title", @"url", nil];
}

-(NSString*)title {
    return @"placeholder title";
}

-(NSString*)url {
    return [article URL];
}

-(NSArray*)links {
    NSMutableArray *links = [NSMutableArray array];
    
    LTWTokens *tokens = [article tokensForField:@"body"];
    
    for (NSUInteger tokenIndex = 0; tokenIndex < [tokens count]; tokenIndex++) {
        for (LTWTokenTag *tag in [tokens tagsStartingAtTokenIndex:tokenIndex]) {
            if ([[tag tagName] isEqual:@"linked_to"]) {
                LTWGUILink *link = [[[LTWGUILink alloc] init] autorelease];
                [link setAnchor:[tokens tokensFromIndex:tokenIndex toIndex:tokenIndex propagateTags:YES]];
                [link setTarget:[tag tagValue]];
                [links addObject:link];
            }
        }
    }
    
    
    return links;
}

@end