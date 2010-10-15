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
#import "LTWGUIRepresentedObjects.h"

@interface LTWGUIMethodCall : NSObject {
    SEL selector;
    id argument;
}

-(id)initWithSelector:(SEL)selector argument:(id)argument;
-(void)executeWithTarget:(id)target;

@end

@interface LTWGUICommand : NSObject {
    id target;
    NSInvocation *undoInvocation;
    NSInvocation *redoInvocation;
}

-(void)undo;
-(void)redo;

+(id)recordUndoCommandWithTarget:(id)target;
+(id)recordRedoForLastUndoCommand;
+(void)undoLastCommand;
+(void)redoNextCommand;
+(BOOL)canUndo;
+(BOOL)canRedo;

@end

@interface LTWGUIMediator : NSObject {
    LTWGUIController *controller;
    LTWGUIViewAdapter *mainWindow;
    LTWGUIAssessmentMode *assessmentMode;
    NSMutableArray *viewMutations;
    NSMutableArray *pendingMainThreadCalls;
    LTWGUIDownloader *downloader;
    LTWGUIArticle *sourceArticle;
    LTWGUIDatabaseFile *currentAssessmentFile;
}
-(id)initWithArguments:(char**)arguments numArguments:(NSInteger)numArguments;
-(void)doPlatformSpecificInitialisation;
-(void)runPlatformSpecificMainLoop;
-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role;
-(LTWGUIViewAdapter*)viewWithRole:(NSString*)role;
-(void)addObject:(id)object toViewWithRole:(NSString*)role;
-(void)setAssessmentMode:(LTWGUIAssessmentMode*)newAssessmentMode;
-(void)callOnMainThread:(LTWGUIMethodCall*)call;
-(void)displaySourceArticle:(LTWArticle*)article;
-(void)loadNonSourceArticle:(LTWArticle*)article;
-(void)pushStatus:(id)status;
-(void)threadSafePushStatus:(id)status;
-(void)loadAssessmentFile:(LTWGUIDatabaseFile*)assessmentFile;
-(void)revealCurrentAssessmentFile;
-(void)uploadCurrentAssessmentFile;
-(void)submitBugReport;

@end