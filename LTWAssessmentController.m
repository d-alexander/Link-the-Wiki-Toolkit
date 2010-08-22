//
//  LTWAssessmentController.m
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWAssessmentController.h"

#import "LTWTestAssessmentMode.h"
#import "LTWSimpleAssessmentMode.h"

#import "LTWArticle.h"
#import "LTWTokens.h"

@implementation LTWAssessmentController

@synthesize platform;
#ifdef GTK_PLATFORM
@synthesize assessmentsReady;
#endif

+(LTWAssessmentController*)sharedInstance {
    static LTWAssessmentController *sharedInstance = nil;
    if (!sharedInstance) sharedInstance = [[LTWAssessmentController alloc] init];
    return sharedInstance;
}

-(NSMutableDictionary*)articleDictionary {
    static NSMutableDictionary *articles = nil;
    if (!articles) articles = [[NSMutableDictionary alloc] init];
    return articles;
}

-(NSArray*)articleURLs {
    return [[self articleDictionary] allKeys];
}

-(NSArray*)assessmentModes {
    return [NSArray arrayWithObjects:[[[LTWTestAssessmentMode alloc] init] autorelease], [[[LTWSimpleAssessmentMode alloc] init] autorelease], nil];
}

-(void)articlesReadyForAssessment:(NSDictionary*)newArticles {
    [[self articleDictionary] addEntriesFromDictionary:newArticles];
    [platform loadNewArticles];
}

-(LTWArticle*)articleWithURL:(NSString*)url {
    return [[self articleDictionary] objectForKey:url];
}

-(NSDictionary*)targetTreeForArticle:(LTWArticle*)article {
    NSMutableDictionary *tree = [NSMutableDictionary dictionary];
    
    LTWTokens *bodyTokens = [article tokensForField:@"body"];
    
    for (NSUInteger tokenIndex=0; tokenIndex < [bodyTokens count]; tokenIndex++) {
        for (LTWTokenTag *tag in [bodyTokens tagsStartingAtTokenIndex:tokenIndex]) {
            if ([[tag tagName] isEqual:@"linked_to"]) {
                NSMutableDictionary *targetBranch = [tree objectForKey:[tag tagValue]];
                if (!targetBranch) {
                    targetBranch = [NSMutableDictionary dictionary];
                    [tree setObject:targetBranch forKey:[tag tagValue]];
                }
                NSString *anchor = [[bodyTokens _text] substringWithRange:[bodyTokens rangeOfTokenAtIndex:tokenIndex]];
                [targetBranch setObject:anchor forKey:anchor];
            }
        }
    }
    
    return tree;
}

- (id)init {
    if ((self = [super init])) {
        corpus = [[LTWCorpus alloc] initWithImplementationCode:[[[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/TeAra.py"]] autorelease]];
#ifdef GTK_PLATFORM
        assessmentsReady = NO;  
#endif
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end
