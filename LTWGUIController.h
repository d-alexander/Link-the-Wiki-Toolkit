//
//  LTWGUIController.h
//  LTWToolkit
//
//  Created by David Alexander on 24/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWGUIViewAdapter.h"


@interface LTWGUIController : NSObject {

}

-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role context:(id)context;

@end

@interface LTWGUIAssessmentMode : NSObject {
    
}

-(NSString*)GUIDefinitionFilename;
-(BOOL)shouldMutateViewWithRole:(NSString*)role mutationType:(LTWGUIViewMutationType)mutationType object:(id)object;

@end

#pragma mark -
#pragma mark Assessment Modes

@interface LTWGUISimpleAssessmentMode : LTWGUIAssessmentMode {
    
}

@end
