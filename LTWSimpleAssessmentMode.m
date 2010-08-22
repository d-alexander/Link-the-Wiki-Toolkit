//
//  LTWSimpleAssessmentMode.m
//  LTWToolkit
//
//  Created by David Alexander on 16/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWSimpleAssessmentMode.h"


@implementation LTWSimpleAssessmentMode

#pragma mark LTWAssessmentMode

#ifdef GTK_PLATFORM
// NOTE: This is a hack to make the GTK way of loading view information fit in with the current definition of LTWAssessmentMode. We return a string with the path to the appropriate glade file, which is then loaded by LTWGTKPlatform.
-(char*)mainViewForPlatform:(id <LTWGUIPlatform>)platform {
    return "\\\\vmware-host\\Shared Folders\\VMWare Shared\\LTWAssessmentTool-Windows.app\\Contents\\Resources\\SimpleAssessmentMode.glade";
}
#else
-(NSView*)mainViewForPlatform:(id <LTWGUIPlatform>)platform {
    return mainView;
}
#endif

-(void)selectionChangedTo:(id)newSelection forRole:(NSString*)role {
    NSLog(@"%@: %@'s selection changed to %@", self, role, newSelection);
}

#pragma mark Miscellaneous

- (id)init {
    if ((self = [super init])) {
#ifndef GTK_PLATFORM
        [NSBundle loadNibNamed:@"LTWSimpleAssessmentMode" owner:self];
#endif
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end
