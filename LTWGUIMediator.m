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

#ifdef GTK_PLATFORM
#include <windows.h>
#endif

/*
 This class co-ordinates communication between the other classes that make up the GUI. Under Cocoa, it will probably also act as the NSApplicationDelegate, although I haven't decided that yet.
 The objects created by this one generally think of it as their "delegate", rather than as a LTWGUIMediator per se. Therefore, at some point I may decide to create a sort of "context" class that gets passed as a parameter to certain other classes' methods so that they can call-back to it if necessary. The most likely use for this is when the LTWGUIController wants to add values to a view, but those values must first be passed on to the appropriate assessment mode for possible further processsing. Since there may be many values, it wouldn't be very nice to try to have them returned from the method, so instead they could each be added via a separate call to the context.
 */
@implementation LTWGUIMediator

-(id)initWithArguments:(char**)arguments numArguments:(NSInteger)numArguments {
    if ((self = [super init])) {
        
        [self doPlatformSpecificInitialisation];
        
        pendingMainThreadCalls = [[NSMutableArray alloc] init];
        controller = [[LTWGUIController alloc] init];
        
        NSString *dataPath;
        NSString *resourcePath;
        
#ifdef GTK_PLATFORM
        NSMutableArray *pathComponents = [[[NSString stringWithUTF8String:arguments[0]] componentsSeparatedByString:@"\\"] mutableCopy];
        [pathComponents removeLastObject];
        resourcePath = [pathComponents componentsJoinedByString:@"\\"];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"assessment_files"];
        dataPath = [pathComponents componentsJoinedByString:@"\\"];
#else
        resourcePath = [[NSBundle mainBundle] resourcePath];
        dataPath = resourcePath;
#endif
        
        [LTWGUIViewAdapter setGUIDefinitionPath:resourcePath];
        
#ifdef GTK_PLATFORM
        mainWindow = [LTWGUIViewAdapter loadViewsFromFile:@"MainWindow.glade" withDelegate:self returningViewWithRole:@"mainWindow"];
#else
        mainWindow = [LTWGUIViewAdapter loadViewsFromFile:@"MainWindow.nib" withDelegate:self returningViewWithRole:@"mainWindow"];
#endif
        
        [controller GUIDidLoadWithContext:self];
        
        for (LTWGUIAssessmentMode *mode in [LTWGUIAssessmentMode assessmentModes]) {
            [self addObject:mode toViewWithRole:@"assessmentModeSelector"];
        }
        
        assessmentMode = nil;
        [self setAssessmentMode:[[LTWGUIAssessmentMode assessmentModes] objectAtIndex:0]];
        
        NSString *proxyHostname = (numArguments >= 2) ? [NSString stringWithUTF8String:arguments[1]] : nil;
        NSUInteger proxyPort = (numArguments >= 3) ? atoi(arguments[2]) : 0;
        NSString *proxyUsername = (numArguments >= 4) ? [NSString stringWithUTF8String:arguments[3]] : nil;
        NSString *proxyPassword = (numArguments >= 5) ? [NSString stringWithUTF8String:arguments[4]] : nil;
        
        downloader = [[LTWGUIDownloader alloc] initWithDelegate:self proxyHostname:proxyHostname proxyPort:proxyPort proxyUsername:proxyUsername proxyPassword:proxyPassword dataPath:dataPath];
        [self runPlatformSpecificMainLoop];
        
        [LTWDatabase closeAllDatabases];
        
    }
    
    return self;
}

-(void)displaySourceArticle:(LTWArticle*)article {
    LTWGUIArticle *articleRepresentation = [[[LTWGUIArticle alloc] init] autorelease];
    [articleRepresentation setArticle:article];
    [self addObject:[article tokensForField:@"body"] toViewWithRole:@"sourceArticleBody"];
    
    [(LTWGUIGenericTreeViewAdapter*)[self viewWithRole:@"sourceArticleLinks"] removeAllObjects];
    
    sourceArticle = [articleRepresentation retain];
}

-(void)loadNonSourceArticle:(LTWArticle*)article {
    LTWGUIArticle *articleRepresentation = [[[LTWGUIArticle alloc] init] autorelease];
    [articleRepresentation setArticle:article];
    [(LTWGUITextViewAdapter*)[self viewWithRole:@"targetArticleBody"] preCreateModelForObject:[article tokensForField:@"body"]];
}

-(void)finishedLoadingArticles {
    for (LTWGUILink *link in [sourceArticle links]) {
        [self addObject:link toViewWithRole:@"sourceArticleLinks"];
    }
    [(LTWGUIGenericTreeViewAdapter*)[self viewWithRole:@"sourceArticleLinks"] expandNodes];
}

-(void)setKnownIssues:(NSString*)knownIssues {
    [self addObject:knownIssues toViewWithRole:@"knownIssues"];
}

-(void)loadAssessmentFile:(LTWGUIDatabaseFile*)assessmentFile {
    [downloader startLoadAssessmentFile:[assessmentFile filename]];
    currentAssessmentFile = [assessmentFile retain];
}

-(void)revealCurrentAssessmentFile {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *filename = [currentAssessmentFile filePath];
#ifdef GTK_PLATFORM
    ShellExecute(NULL, "open", "explorer.exe", [[NSString stringWithFormat:@"/select,%@", filename] UTF8String], NULL, SW_SHOW);
#else
    
#endif
    [pool drain];
}

-(void)uploadCurrentAssessmentFile {
    if (!currentAssessmentFile) return;
    [downloader startUploadAssessmentFile:[currentAssessmentFile filename]];
}

-(void)assessmentFileFound:(LTWGUIDatabaseFile*)file {
    [self addObject:file toViewWithRole:@"assessmentFileSelector"];
}

-(void)pushStatus:(id)status {
    [self addObject:status toViewWithRole:@"statusBar"];
}

// This method is safe to be called from other threads.
-(void)threadSafePushStatus:(id)status {
    LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(pushStatus:) argument:status];
    [self callOnMainThread:call];
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
    g_timeout_add(1000, checkForMainThreadCalls, self);
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

-(LTWGUIViewAdapter*)viewWithRole:(NSString*)role {
    return [LTWGUIViewAdapter adapterWithRole:role];
}

-(void)addObject:(id)object toViewWithRole:(NSString*)role {
    [[self viewWithRole:role] addObject:object];
}

-(void)setAssessmentMode:(LTWGUIAssessmentMode*)newAssessmentMode {
    [assessmentMode release];
    assessmentMode = [newAssessmentMode retain];
    
    [self addObject:assessmentMode toViewWithRole:@"assessmentModeContainer"];
    [assessmentMode assessmentModeDidLoadWithContext:self];
}

-(void)submitBugReport {
    NSString *bugReportText = [(LTWGUITextViewAdapter*)[self viewWithRole:@"bugReportText"] text];
    [downloader startSubmitBugReport:bugReportText];
}

-(void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end

@implementation LTWGUICommand

static NSMutableArray *undoStack;
static NSMutableArray *redoStack;
static id lastUndoCommand = nil;
static BOOL executingCommand = NO;

+(void)initialize {
    undoStack = [[NSMutableArray alloc] init];
    redoStack = [[NSMutableArray alloc] init];
}

+(id)recordUndoCommandWithTarget:(id)target {
    if (executingCommand) return nil;
    
    LTWGUICommand *command = [[LTWGUICommand alloc] init];
    command->target = [target retain];
    lastUndoCommand = [command retain];
    return [command autorelease];
}

+(id)recordRedoForLastUndoCommand {
    if (executingCommand) return nil;
    
    LTWGUICommand *command = lastUndoCommand;
    lastUndoCommand = nil;
    return [command autorelease];
}

-(void)forwardInvocation:(NSInvocation*)invocation {
    if (!undoInvocation) {
        [invocation setTarget:target];
        [invocation retainArguments];
        undoInvocation = [invocation retain];
    }else if (!redoInvocation) {
        [invocation setTarget:target];
        [invocation retainArguments];
        redoInvocation = [invocation retain];
        [undoStack addObject:self];
    }
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
    return [target methodSignatureForSelector:selector];
}

-(void)undo {
    [undoInvocation invoke];
}

-(void)redo {
    [redoInvocation invoke];
}

+(void)undoLastCommand {
    if ([undoStack count] > 0) {
        executingCommand = YES;
        LTWGUICommand *command = [undoStack lastObject];
        [command undo];
        [redoStack addObject:command];
        [undoStack removeLastObject];
        executingCommand = NO;
    }
}

+(void)redoNextCommand {
    if ([redoStack count] > 0) {
        executingCommand = YES;
        LTWGUICommand *command = [redoStack lastObject];
        NSLog(@"redoing command %@", command);
        [command redo];
        [undoStack addObject:command];
        [redoStack removeLastObject];
        executingCommand = NO;
    }
}

+(BOOL)canUndo {
    return [undoStack count] > 0;
}

+(BOOL)canRedo {
    return [redoStack count] > 0;
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
