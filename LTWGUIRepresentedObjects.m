//
//  LTWGUIRepresentedObjects.m
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIRepresentedObjects.h"

static NSMutableDictionary *articlesByURL = nil;

@implementation LTWGUILink

@synthesize anchor;
@synthesize target;

+(void)initialize {
    if (!articlesByURL) articlesByURL = [[NSMutableDictionary alloc] init];
}

-(void)setIsRelevant:(BOOL)theValue {
    if (theValue) {
        [anchor addTag:[[LTWTokenTag alloc] initWithName:@"is_relevant" value:[NSNumber numberWithBool:YES]]];
    }else{
        [[anchor tagWithName:@"is_relevant" startingAtTokenIndex:0] remove];
    }
}

-(void)setTargetURL:(NSString*)targetURL {
    [self setTarget:[articlesByURL objectForKey:targetURL]];
}

@synthesize isRelevant;

@end

@implementation LTWGUIArticle

+(void)initialize {
    if (!articlesByURL) articlesByURL = [[NSMutableDictionary alloc] init];
}

-(LTWArticle*)article {
    return article;
}

-(void)setArticle:(LTWArticle*)theArticle {
    article = [theArticle retain];
    [articlesByURL setObject:theArticle forKey:[theArticle URL]];
}

-(NSString*)title {
    return [[article tokensForField:@"title"] description];
}

-(NSString*)description {
    return [self title];
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
                [link setTargetURL:[tag tagValue]];
                [links addObject:link];
            }
        }
    }
    
    
    return links;
}

@end