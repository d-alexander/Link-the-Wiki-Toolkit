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

@interface LTWAssessmentController : NSObject {
    LTWCorpus *corpus;
}

+(LTWAssessmentController*)sharedInstance;
-(NSArray*)articleURLs;
-(NSArray*)assessmentModes;
-(LTWArticle*)articleWithURL:(NSString*)url;

@end
