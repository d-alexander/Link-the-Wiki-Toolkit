//
//  LTWTestAssessmentMode.m
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWTestAssessmentMode.h"


@implementation LTWTestAssessmentMode

#pragma mark LTWAssessmentMode

-(NSView*)mainViewForPlatform:(id <LTWGUIPlatform>)platform {
    return mainView;
}

-(void)selectionChangedTo:(id)newSelection forRole:(NSString*)role {
    NSLog(@"%@: %@'s selection changed to %@", self, role, newSelection);
}

#pragma mark Miscellaneous

- (id)init {
    if ((self = [super init])) {
        [NSBundle loadNibNamed:@"LTWTestAssessmentMode" owner:self];
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end
