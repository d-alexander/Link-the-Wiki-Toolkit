//
//  LTWAssessmentController.m
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWAssessmentController.h"

#import "LTWTestAssessmentMode.h"

@implementation LTWAssessmentController

+(LTWAssessmentController*)sharedInstance {
    static LTWAssessmentController *sharedInstance = nil;
    if (!sharedInstance) sharedInstance = [[LTWAssessmentController alloc] init];
    return sharedInstance;
}

-(NSArray*)articleURLs {
    return [corpus articleURLs];
}

-(NSArray*)assessmentModes {
    return [NSArray arrayWithObjects:[[LTWTestAssessmentMode alloc] init], nil];
}

- (id)init {
    if ((self = [super init])) {
        corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/TeAra.py"]]];
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end
