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

@implementation LTWAssessmentController

+(LTWAssessmentController*)sharedInstance {
    static LTWAssessmentController *sharedInstance = nil;
    if (!sharedInstance) sharedInstance = [[LTWAssessmentController alloc] init];
    return sharedInstance;
}

-(NSDictionary*)articleDictionary {
    static NSDictionary *articles = nil;
    if (!articles) articles = [[[LTWDatabase sharedInstance] loadArticles] retain];
    return articles;
}

-(NSArray*)articleURLs {
    return [[self articleDictionary] allKeys];
}

-(NSArray*)assessmentModes {
    return [NSArray arrayWithObjects:[[LTWSimpleAssessmentMode alloc] init], [[LTWTestAssessmentMode alloc] init], nil];
}

-(LTWArticle*)articleWithURL:(NSString*)url {
    return [[self articleDictionary] objectForKey:url];
}

- (id)init {
    if ((self = [super init])) {
        corpus = [[LTWCorpus alloc] initWithImplementationCode:[[[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/TeAra.py"]] autorelease]];
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end
