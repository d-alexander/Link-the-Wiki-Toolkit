//
//  LTWGUIRepresentedObjects.m
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIRepresentedObjects.h"
#import "LTWGUIMediator.h"

static NSMutableDictionary *articlesByURL = nil;

@implementation LTWGUILink

@synthesize target;

+(void)initialize {
    if (!articlesByURL) articlesByURL = [[NSMutableDictionary alloc] init];
}

-(void)setAnchor:(LTWGUIAnchor*)theAnchor {
    anchor = [theAnchor retain];
    relevanceTag = [[anchor tokens] tagWithName:@"is_relevant" startingAtTokenIndex:0];
    isRelevant = (relevanceTag != nil);
}

-(LTWGUIAnchor*)anchor {
    return anchor;
}

-(void)setIsRelevant:(BOOL)theValue {
    NSLog(@"[%@ setIsRelevant:%d]", self, theValue);
    
    isRelevant = theValue;
    if (theValue) {
        relevanceTag = [[LTWTokenTag alloc] initWithName:@"is_relevant" value:[NSNumber numberWithBool:YES]];
        [[anchor tokens] addTag:relevanceTag];
    }else if (relevanceTag) {
        [[anchor tokens] _removeTag:relevanceTag fromIndex:0];
        relevanceTag = nil;
    }
    
    [[LTWGUICommand recordUndoCommandWithTarget:self] setIsRelevant:!theValue];
    [[LTWGUICommand recordRedoForLastUndoCommand] setIsRelevant:theValue];
}

-(BOOL)isRelevant {
    return isRelevant;
}

-(void)setTargetURL:(NSString*)targetURL {
    [self setTarget:[articlesByURL objectForKey:targetURL]];
}

@end

@implementation LTWGUILink (Additions)

-(BOOL)anchorIsRelevant {
    return [anchor isRelevant];
}

-(void)setAnchorIsRelevant:(BOOL)theValue {
    [anchor setValue:[NSNumber numberWithBool:theValue] forKey:@"isRelevant"];
}

-(BOOL)targetIsRelevant {
    return [target isRelevant];
}

-(void)setTargetIsRelevant:(BOOL)theValue {
    [target setValue:[NSNumber numberWithBool:theValue] forKey:@"isRelevant"];
}

+(NSSet*)keyPathsForValuesAffectingAnchorIsRelevant {
    return [NSSet setWithObjects:@"anchor.isRelevant", nil];
}

+(NSSet*)keyPathsForValuesAffectingTargetIsRelevant {
    return [NSSet setWithObjects:@"target.isRelevant", nil];
}

@end

@implementation LTWGUIArticle

-(void)setIsRelevant:(BOOL)theValue {
    isRelevant = theValue;
    if (theValue) {
        relevanceTag = [[LTWTokenTag alloc] initWithName:@"target_is_relevant" value:[NSNumber numberWithBool:YES]];
        [[article tokensForField:@"body"] addTag:relevanceTag];
    }else if (relevanceTag) {
        [[article tokensForField:@"body"] _removeTag:relevanceTag fromIndex:0];
        relevanceTag = nil;
    }
    
    [[LTWGUICommand recordUndoCommandWithTarget:self] setIsRelevant:!theValue];
    [[LTWGUICommand recordRedoForLastUndoCommand] setIsRelevant:theValue];
}

-(BOOL)isRelevant {
    return isRelevant;
}

+(void)initialize {
    if (!articlesByURL) articlesByURL = [[NSMutableDictionary alloc] init];
}

-(LTWArticle*)article {
    return article;
}

-(void)setArticle:(LTWArticle*)theArticle {
    article = [theArticle retain];
    [articlesByURL setObject:self forKey:[theArticle  URL]];
    relevanceTag = [[article tokensForField:@"body"] tagWithName:@"target_is_relevant" startingAtTokenIndex:0];
    isRelevant = (relevanceTag != nil);
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
                LTWGUIAnchor *anchor = [[[LTWGUIAnchor alloc] init] autorelease];
                [anchor setTokens:[tokens tokensFromIndex:tokenIndex toIndex:tokenIndex propagateTags:YES]];
                [link setAnchor:anchor];
                [link setTargetURL:[tag tagValue]];
                if ([link target]) [links addObject:link];
            }
        }
    }
    
    
    return links;
}

@end

@implementation LTWGUIAnchor

-(LTWTokens*)tokens {
    return tokens;
}

-(void)setTokens:(LTWTokens*)theTokens {
    tokens = [theTokens retain];
    relevanceTag = [tokens tagWithName:@"anchor_is_relevant" startingAtTokenIndex:0];
    isRelevant = (relevanceTag != nil);
}

-(void)setIsRelevant:(BOOL)theValue {
    isRelevant = theValue;
    if (theValue) {
        relevanceTag = [[LTWTokenTag alloc] initWithName:@"anchor_is_relevant" value:[NSNumber numberWithBool:YES]];
        [tokens addTag:relevanceTag];
    }else if (relevanceTag) {
        [tokens _removeTag:relevanceTag fromIndex:0];
        relevanceTag = nil;
    }
    
    [[LTWGUICommand recordUndoCommandWithTarget:self] setIsRelevant:!theValue];
    [[LTWGUICommand recordRedoForLastUndoCommand] setIsRelevant:theValue];
}

-(NSString*)description {
    return [tokens description];
}

-(BOOL)isRelevant {
    return isRelevant;
}

@end

@implementation LTWGUIDatabaseFile

@synthesize filename;
@synthesize filePath;

@end