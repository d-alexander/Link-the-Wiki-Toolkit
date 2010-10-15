//
//  LTWGUIController.h
//  LTWToolkit
//
//  Created by David Alexander on 24/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWGUIViewAdapter.h"

@class LTWGUIUndoGroup;

@interface LTWGUIController : NSObject {
    LTWGUIUndoGroup *documentLoadingUndoGroup;
    LTWGUIUndoGroup *targetDocumentLoadingUndoGroup;
}

-(void)GUIDidLoadWithContext:(id)context;
-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role context:(id)context;

@end

@interface LTWGUIAssessmentMode : NSObject {
    
}

-(NSString*)GUIDefinitionFilename;
-(void)assessmentModeDidLoadWithContext:(id)context;
+(NSArray*)assessmentModes;

@end

#pragma mark -
#pragma mark Assessment Modes

@interface LTWGUISimpleAssessmentMode : LTWGUIAssessmentMode {
    
}

@end

@interface LTWGUISortedAssessmentMode : LTWGUIAssessmentMode {
    
}

@end

@interface LTWGUIAnchorTargetAssessmentMode : LTWGUIAssessmentMode {
    
}

@end

@interface LTWGUITargetAnchorAssessmentMode : LTWGUIAssessmentMode {
    
}

@end
