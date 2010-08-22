//
//  LTWSimpleAssessmentMode.h
//  LTWToolkit
//
//  Created by David Alexander on 16/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWAssessmentMode.h"

@interface LTWSimpleAssessmentMode : NSObject <LTWAssessmentMode> {
    IBOutlet NSView *mainView;
}

@end
