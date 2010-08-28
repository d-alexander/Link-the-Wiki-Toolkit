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
        mainWindow = [LTWGUIViewAdapter loadViewsFromFile:@"MainMenu" withDelegate:self returningViewWithRole:@"mainView"];
#endif
        
        assessmentMode = nil;
        viewMutations = nil;
        
        // Put the available assessment modes into the selector.
        [self mutateViewWithRole:@"assessmentModeSelector" mutationType:ADD object:[[[LTWGUISimpleAssessmentMode alloc] init] autorelease] caller:self];
        
        [[LTWGUIDownloader alloc] initWithDelegate:self];
        [self runPlatformSpecificMainLoop];
        
    }
    
    return self;
}

-(void)articleLoaded:(LTWArticle*)article {
    LTWGUIArticle *articleRepresentation = [[[LTWGUIArticle alloc] init] autorelease];
    [articleRepresentation setArticle:article];
    [self mutateViewWithRole:@"articleSelector" mutationType:ADD object:articleRepresentation caller:self];
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
    @synchronized (pendingMainThreadCalls) {
        [pendingMainThreadCalls addObject:call];
    }
}

gboolean checkForMainThreadCalls(void *data) {
    LTWGUIMediator *mediatorInstance = (LTWGUIMediator*)data;
    [mediatorInstance checkForMainThreadCalls];
    return TRUE;
}

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
    
#endif
}

-(void)runPlatformSpecificMainLoop {
#ifdef GTK_PLATFORM
    gtk_main();
#else
    
#endif
}

// NOTE: Should this be the only event-handling method, or should there be others, e.g. for "checkbox ticked", "button pressed", etc?
// NOTE: Should we have a special "iterator" type so that the reference to the object can always be used to remove/change the object efficiently?
-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role {
    NSLog(@"objectSelected:%@ inViewWithRole:%@", selectedObject, role);
    
    viewMutations = [[NSMutableArray alloc] init];
    
    [controller objectSelected:selectedObject inViewWithRole:role context:self];
    
    for (LTWGUIViewMutation *mutation in viewMutations) {
        // By calling shouldMutateViewWithRole:mutationType:object:, we give the assessmentMode a chance to cause more mutations. It can also stop the current one by returning NO.
        if (!assessmentMode || [assessmentMode shouldMutateViewWithRole:[mutation role] mutationType:[mutation type] object:[mutation object]]) {
            [self mutateViewWithRole:[mutation role] mutationType:[mutation type] object:[mutation object] caller:assessmentMode];
        }
    }
    
    [viewMutations release];
    viewMutations = nil;
    
}

// NOTE: We need to insert all mutations created by the controller into an array so that they can be vetted by the assessmentMode before being passed on. LTWGUIMutation serves only as a "boxing" type to allow us to insert mutations into an array.
// NOTE: If an assessmentMode implicitly approves a mutation by returning YES from shouldMutateViewWithRole:mutationType:object, the "caller" is considered to be the assessmentMode itself.
-(void)mutateViewWithRole:(NSString*)role mutationType:(LTWGUIViewMutationType)mutationType object:(id)object caller:(id)caller {
    if (caller == controller) {
        [viewMutations addObject:[[[LTWGUIViewMutation alloc] initWithRole:role type:mutationType object:object] autorelease]];
    }else{
        [[LTWGUIViewAdapter adapterWithRole:role] applyMutationWithType:mutationType object:object];
    }
}

-(void)setAssessmentMode:(LTWGUIAssessmentMode*)newAssessmentMode {
    NSLog(@"assessmentMode set to %@", newAssessmentMode);
    [assessmentMode release];
    assessmentMode = [newAssessmentMode retain];
    
    [self mutateViewWithRole:@"assessmentModeContainer" mutationType:ADD object:assessmentMode caller:self];
}

-(void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end

@implementation LTWGUIViewMutation

-(id)initWithRole:(NSString*)theRole type:(LTWGUIViewMutationType)theType object:(id)theObject {
    if (self = [super init]) {
        role = [theRole retain];
        type = theType;
        object = [theObject retain];
    }
    return self;
}

@synthesize role;
@synthesize type;
@synthesize object;

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
