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

@interface LTWGUIMediator : NSObject {
    LTWGUIController *controller;
    LTWGUIViewAdapter *mainWindow;
    LTWGUIAssessmentMode *assessmentMode;
    NSMutableArray *viewMutations;
    NSMutableArray *pendingMainThreadCalls;
}

-(void)doPlatformSpecificInitialisation;
-(void)runPlatformSpecificMainLoop;
-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role;
-(void)mutateViewWithRole:(NSString*)role mutationType:(LTWGUIViewMutationType)mutationType object:(id)object caller:(id)caller;
-(void)setAssessmentMode:(LTWGUIAssessmentMode*)newAssessmentMode;
-(void)callOnMainThread:(LTWGUIMethodCall*)call;
-(void)articleLoaded:(LTWArticle*)article;

@end

@interface LTWGUIViewMutation : NSObject {
    NSString *role;
    LTWGUIViewMutationType type;
    id object;
}

-(id)initWithRole:(NSString*)theRole type:(LTWGUIViewMutationType)theType object:(id)theObject;

@property (readonly) NSString *role;
@property (readonly) LTWGUIViewMutationType type;
@property (readonly) id object;

@end