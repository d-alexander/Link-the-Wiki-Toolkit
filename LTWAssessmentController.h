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
}

+(LTWAssessmentController*)sharedInstance;
-(NSArray*)articleURLs;
-(NSArray*)assessmentModes;
-(LTWArticle*)articleWithURL:(NSString*)url;
-(void)articlesReadyForAssessment:(NSDictionary*)newArticles;

@property (nonatomic, retain) id <LTWGUIPlatform> platform;

@end
