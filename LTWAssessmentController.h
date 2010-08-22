//
//  LTWAssessmentController.h
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWCorpus.h"
#import "LTWPythonUtils.h"
#import "LTWArticle.h"

#import "LTWGUIPlatform.h"

@interface LTWAssessmentController : NSObject {
    LTWCorpus *corpus;
    id <LTWGUIPlatform> platform;
    
#ifdef GTK_PLATFORM
    NSDictionary *assessmentsReady;
#endif
}

+(LTWAssessmentController*)sharedInstance;
-(NSArray*)articleURLs;
-(NSArray*)assessmentModes;
-(LTWArticle*)articleWithURL:(NSString*)url;
-(void)articlesReadyForAssessment:(NSDictionary*)newArticles;
-(NSDictionary*)targetTreeForArticle:(LTWArticle*)article;

@property (nonatomic, retain) id <LTWGUIPlatform> platform;
#ifdef GTK_PLATFORM
@property (retain) NSDictionary *assessmentsReady;
#endif

@end
