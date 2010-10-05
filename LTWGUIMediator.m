//
//  LTWGUIMediator.m
//  LTWToolkit
//
//  Created by David Alexander on 24/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIMediator.h"
#import "LTWArticle.h"
#import "LTWGUIRepresentedObjects.h"
#import "LTWGUIViewAdapter.h"

/*
 This class co-ordinates communication between the other classes that make up the GUI. Under Cocoa, it will probably also act as the NSApplicationDelegate, although I haven't decided that yet.
 The objects created by this one generally think of it as their "delegate", rather than as a LTWGUIMediator per se. Therefore, at some point I may decide to create a sort of "context" class that gets passed as a parameter to certain other classes' methods so that they can call-back to it if necessary. The most likely use for this is when the LTWGUIController wants to add values to a view, but those values must first be passed on to the appropriate assessment mode for possible further processsing. Since there may be many values, it wouldn't be very nice to try to have them returned from the method, so instead they could each be added via a separate call to the context.
 */
@implementation LTWGUIMediator

-(id)init {
    if ((self = [super init])) {
        
        [self doPlatformSpecificInitialisation];
        
        pendingMainThreadCalls = [[NSMutableArray alloc] init];
        controller = [[LTWGUIController alloc] init];
        
#ifdef GTK_PLATFORM
        [LTWGUIViewAdapter setGUIDefinitionPath:@"\\\\vmware-host\\Shared Folders\\VMWare Shared\\LTWAssessmentTool-Windows.app\\Contents\\Resources\\"];
        mainWindow = [LTWGUIViewAdapter loadViewsFromFile:@"MainWindow.glade" withDelegate:self returningViewWithRole:@"mainWindow"];
#else
        [LTWGUIViewAdapter setGUIDefinitionPath:[[NSBundle mainBundle] resourcePath]];
        mainWindow = [LTWGUIViewAdapter loadViewsFromFile:@"MainWindow.nib" withDelegate:self returningViewWithRole:@"mainWindow"];
#endif
        
        [controller GUIDidLoadWithContext:self];
        
        assessmentMode = nil;
        
        for (LTWGUIAssessmentMode *mode in [LTWGUIAssessmentMode assessmentModes]) {
            [self addObject:mode toViewWithRole:@"assessmentModeSelector"];
        }
        
        downloader = [[LTWGUIDownloader alloc] initWithDelegate:self];
        [self runPlatformSpecificMainLoop];
        
    }
    
    return self;
}

-(void)displaySourceArticle:(LTWArticle*)article {
    LTWGUIArticle *articleRepresentation = [[[LTWGUIArticle alloc] init] autorelease];
    [articleRepresentation setArticle:article];
    [self addObject:[article tokensForField:@"body"] toViewWithRole:@"sourceArticleBody"];
    
    [(LTWGUIGenericTreeViewAdapter*)[self viewWithRole:@"sourceArticleLinks"] removeAllObjects];
    
    for (LTWGUILink *link in [articleRepresentation links]) {
        [self addObject:link toViewWithRole:@"sourceArticleLinks"];
    }
}

-(void)loadNonSourceArticle:(LTWArticle*)article {
    LTWGUIArticle *articleRepresentation = [[[LTWGUIArticle alloc] init] autorelease];
    [articleRepresentation setArticle:article];
    // NOTE: Should make sure that everything gets refreshed here.
}

-(void)loadAssessmentFile:(NSString*)assessmentFile {
    [downloader startLoadAssessmentFile:assessmentFile];
}

-(void)assessmentFileFound:(NSString*)filename {
    [self addObject:filename toViewWithRole:@"assessmentFileSelector"];
}

-(void)pushStatus:(id)status {
    [self addObject:status toViewWithRole:@"statusBar"];
}

-(void)checkForMainThreadCalls {
    @synchronized (pendingMainThreadCalls) {
        for (LTWGUIMethodCall *call in pendingMainThreadCalls) {
            [call executeWithTarget:self];
        }
        [pendingMainThreadCalls removeAllObjects];
    }
}

-(void)callOnMainThread:(LTWGUIMethodCall*)call {
#ifdef GTK_PLATFORM
    @synchronized (pendingMainThreadCalls) {
        [pendingMainThreadCalls addObject:call];
    }
#else
    [call performSelectorOnMainThread:@selector(executeWithTarget:) withObject:self waitUntilDone:NO];
#endif
}

#ifdef GTK_PLATFORM
gboolean checkForMainThreadCalls(void *data) {
    LTWGUIMediator *mediatorInstance = (LTWGUIMediator*)data;
    [mediatorInstance checkForMainThreadCalls];
    return TRUE;
}
#endif

-(void)doPlatformSpecificInitialisation {
#ifdef GTK_PLATFORM
    int argc = 1;
    char *argv[] = {"LTWAssessmentTool", NULL};
    char **argvPtr = argv;
    gtk_init(&argc, &argvPtr);
    
    // Set up a timeout to repeatedly check for calls from other threads.
    // NOTE: Should make this work using signals instead.
    g_timeout_add(100, checkForMainThreadCalls, self);
#else
    [NSApplication sharedApplication];
#endif
}

-(void)runPlatformSpecificMainLoop {
#ifdef GTK_PLATFORM
    gtk_main();
#else
    [NSApp run];
#endif
}

-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role {
    [controller objectSelected:selectedObject inViewWithRole:role context:self];
}

-(LTWGUIUndoGroup*)newUndoGroup {
    return [[LTWGUIUndoGroup alloc] init];
}

-(LTWGUIViewAdapter*)viewWithRole:(NSString*)role {
    return [LTWGUIViewAdapter adapterWithRole:role];
}

-(void)addObject:(id)object toViewWithRole:(NSString*)role {
    [[self viewWithRole:role] addObject:object];
}

-(void)setAssessmentMode:(LTWGUIAssessmentMode*)newAssessmentMode {
    NSLog(@"assessmentMode set to %@", newAssessmentMode);
    [assessmentMode release];
    assessmentMode = [newAssessmentMode retain];
    
    [self addObject:assessmentMode toViewWithRole:@"assessmentModeContainer"];
    [assessmentMode assessmentModeDidLoadWithContext:self];
}

-(void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end

@implementation LTWGUIUndoableOperation


-(void)dealloc {
    [addedOrConfiguredView release];
    [addedOrChangedObject release];
    [changedProperty release];
    [preChangePropertyValue release];
    [configurationArgument release];
    [super dealloc];
}

+(id)operationAddingObject:(id)theObject toView:(LTWGUIViewAdapter*)theView {
    LTWGUIUndoableOperation *operation = [[[LTWGUIUndoableOperation alloc] init] autorelease];
    
    operation->type = ADD;
    operation->addedOrConfiguredView = [theView retain];
    operation->addedOrChangedObject = [theObject retain];
    
    return operation;
}

+(id)operationChangingProperty:(NSString*)theProperty ofObject:(id)theObject fromValue:(id)theOldValue {
    LTWGUIUndoableOperation *operation = [[[LTWGUIUndoableOperation alloc] init] autorelease];
    
    operation->type = CHANGE;
    operation->addedOrChangedObject = [theObject retain];
    operation->changedProperty = [theProperty retain];
    operation->preChangePropertyValue = [theOldValue retain];
    
    return operation;
}

/*
 NOTE: Not properly implemented yet. (Should 'argument' be the OLD value of the configuration?)
 */
+(id)operationConfiguringView:(id)theView type:(UndoableConfigurationType)theType argument:(id)theArgument {
    LTWGUIUndoableOperation *operation = [[[LTWGUIUndoableOperation alloc] init] autorelease];
    
    operation->addedOrConfiguredView = [theView retain];
    operation->configurationType = theType;
    operation->configurationArgument = [theArgument retain];
    
    return operation;
}

-(void)undo {
    switch (type) {
        case ADD:
            if ([addedOrConfiguredView respondsToSelector:@selector(removeObject:hierarchyValues:)]) {
                [addedOrConfiguredView removeObject:addedOrChangedObject];
            }
            break;
        case CHANGE:
            [addedOrChangedObject setValue:preChangePropertyValue forKey:changedProperty];
            break;
        case CONFIGURE:
            /*
            switch (configurationType) {
                case COLUMN_PROPERTIES:
                    [addedOrConfiguredView setDisplayProperties:configurationArgument withClasses:???];
                    break;
                case HIERARCHY_PROPERTIES:
                    [addedOrConfiguredView setHierarchyProperties:configurationArgument];
                    break;
            }
             */
            break;
    }
}

@end

@implementation LTWGUIUndoGroup

static NSMutableArray *undoGroups;

+(void)initialize {
    NSLog(@"initialize called");
    undoGroups = [[NSMutableArray alloc] init];
}

+(void)addOperationToCurrentUndoGroup:(LTWGUIUndoableOperation*)operation {
    if ([undoGroups count] == 0 || ((LTWGUIUndoGroup*)[undoGroups lastObject])->isFinished) {
        LTWGUIUndoGroup *group = [self startNewUndoGroup];
        [group->operations addObject:operation];        
        [group finish];
    }else{
        [((LTWGUIUndoGroup*)[undoGroups lastObject])->operations addObject:operation];
    }
}

+(LTWGUIUndoGroup*)startNewUndoGroup {
    LTWGUIUndoGroup *group = [[[LTWGUIUndoGroup alloc] init] autorelease];
    [undoGroups addObject:group];
    return group;
}

-(id)init {
    if (self = [super init]) {
        operations = [[NSMutableArray alloc] init];
    }
    return self;
}

+(void)undoMostRecentGroup {
    if ([undoGroups count] > 0) {
        [[undoGroups lastObject] undo];
    }
}

-(void)finish {
    isFinished = YES;
}

-(void)undo {
    if (isUndone) return;
    
    while ([undoGroups count] > 0 && [undoGroups lastObject] != self) [[undoGroups lastObject] undo];
    
    if ([undoGroups count] == 0) return;
    
    while ([operations count] > 0) {
        [[operations lastObject] undo];
        [operations removeLastObject];
    }
    
    [undoGroups removeLastObject];
}

@end

@implementation LTWGUIMethodCall

-(id)initWithSelector:(SEL)theSelector argument:(id)theArgument {
    if (self = [super init]) {
        selector = theSelector;
        argument = [theArgument retain];
    }
    return self;
}

-(void)executeWithTarget:(id)target {
    [target performSelector:selector withObject:argument];
}

@end
