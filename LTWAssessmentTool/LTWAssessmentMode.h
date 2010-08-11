//
//  LTWAssessmentMode.h
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWGUIPlatform.h"

@protocol LTWAssessmentMode <NSObject>

// Should we pass the platform here, or just use #ifdefs?
-(NSView*)mainViewForPlatform:(id <LTWGUIPlatform>)platform;
-(void)selectionChangedTo:(id)newSelection forRole:(NSString*)role;

@end
