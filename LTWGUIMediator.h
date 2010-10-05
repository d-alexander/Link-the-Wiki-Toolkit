//
//  LTWGUIMediator.h
//  LTWToolkit
//
//  Created by David Alexander on 24/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWGUIController.h"
#import "LTWGUIViewAdapter.h"
#import "LTWGUIDownloader.h"
#import "LTWArticle.h"

@interface LTWGUIMethodCall : NSObject {
    SEL selector;
    id argument;
}

-(id)initWithSelector:(SEL)selector argument:(id)argument;
-(void)executeWithTarget:(id)target;

@end

typedef enum {ADD, CHANGE, CONFIGURE} UndoableOperationType;
typedef enum {COLUMN_PROPERTIES, HIERARCHY_PROPERTIES} UndoableConfigurationType;

@interface LTWGUIUndoableOperation : NSObject {
    UndoableOperationType type;
    
    id addedOrConfiguredView;
    
    id addedOrChangedObject;
    NSString *changedProperty;
    id preChangePropertyValue;
    
    UndoableConfigurationType configurationType;
    id configurationArgument;
}


+(id)operationAddingObject:(id)theObject toView:(LTWGUIViewAdapter*)theView;
+(id)operationChangingProperty:(NSString*)theProperty ofObject:(id)theObject fromValue:(id)theOldValue;
+(id)operationConfiguringView:(id)theView type:(UndoableConfigurationType)theType argument:(id)theArgument;

-(void)undo;

@end

@interface LTWGUIUndoGroup : NSObject {
    BOOL isFinished;
    BOOL isUndone;
    NSMutableArray *operations;
}

-(void)finish;
-(void)undo;

+(void)addOperationToCurrentUndoGroup:(LTWGUIUndoableOperation*)operation;
+(LTWGUIUndoGroup*)startNewUndoGroup;
+(void)undoMostRecentGroup;

@end

@interface LTWGUIMediator : NSObject {
    LTWGUIController *controller;
    LTWGUIViewAdapter *mainWindow;
    LTWGUIAssessmentMode *assessmentMode;
    NSMutableArray *viewMutations;
    NSMutableArray *pendingMainThreadCalls;
    LTWGUIDownloader *downloader;
}

-(void)doPlatformSpecificInitialisation;
-(void)runPlatformSpecificMainLoop;
-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role;
-(LTWGUIUndoGroup*)newUndoGroup;
-(LTWGUIViewAdapter*)viewWithRole:(NSString*)role;
-(void)addObject:(id)object toViewWithRole:(NSString*)role;
-(void)setAssessmentMode:(LTWGUIAssessmentMode*)newAssessmentMode;
-(void)callOnMainThread:(LTWGUIMethodCall*)call;
-(void)displaySourceArticle:(LTWArticle*)article;
-(void)loadNonSourceArticle:(LTWArticle*)article;
-(void)pushStatus:(id)status; // TODO: Make this return something that can be "undone".
-(void)loadAssessmentFile:(NSString*)assessmentFile;

@end