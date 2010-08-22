//
//  LTWCocoaPlatform.m
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifndef GTK_PLATFORM

#import "LTWCocoaPlatform.h"

#import "LTWAssessmentController.h"
#import "LTWTokensView.h"
#import "LTWOverlayTokensView.h"
#import "LTWTokens.h"
#import "LTWRemoteDatabase.h"

@implementation LTWCocoaPlatform

@synthesize window;

#pragma mark LTWGUIPlatform

static LTWCocoaPlatform *sharedInstance = nil;
+(LTWCocoaPlatform*)sharedInstance {
    // The sharedInstance is set by applicationDidFinishLaunching.
    return sharedInstance;
}

-(NSView*)mainView {
    return mainView;
}

-(NSView*)componentWithRole:(NSString*)role inView:(NSView*)view {
    if ([role isEqual:[view roleIfExists]]) return view;
    
    for (NSView *subview in [view subviews]) {
        NSView *component = [self componentWithRole:role inView:subview];
        if (component) return component;
    }
    
    return nil;
}

-(void)setStatus:(NSString*)status {
    [statusSpinner startAnimation:self];
    [statusLabel setStringValue:status];
}

-(void)clearStatus {
    [statusSpinner stopAnimation:self];
    [statusLabel setStringValue:@""];
}

static NSMutableDictionary *representedValues = nil; // Stores data that is currently being shown.

-(void)setRepresentedValue:(id)value forRole:(NSString*)role {
    
    NSView *component = [self componentWithRole:role inView:[self mainView]];
    
    // This tries to "translate" the given value into something that can be displayed by the view.
    
    BOOL success = NO;
    
    if ([value isKindOfClass:[NSArray class]]) {
        if (!representedValues) representedValues = [[NSMutableDictionary alloc] init];
        [representedValues setObject:value forKey:[NSValue valueWithNonretainedObject:component]];
        if ([component isKindOfClass:[NSPopUpButton class]]) {
            NSPopUpButton *button = (NSPopUpButton*)component;
            [button removeAllItems];
            for (id entry in (NSArray*)value) {
                [button addItemWithTitle:[entry description]];
            }
            [button setAction:@selector(popUpButtonSelectionDidChange:)];
            [button setTarget:[LTWCocoaPlatform sharedInstance]];
            success = YES;
        }else if ([component isKindOfClass:[NSTableView class]]) {
            [(NSTableView*)component setDataSource:[LTWCocoaPlatform sharedInstance]];
            [(NSTableView*)component setDelegate:[LTWCocoaPlatform sharedInstance]];
            [(NSTableView*)component reloadData]; // NOTE: This must be called AFTER representedValues has been changed.
            success = YES;
        }
    }else if ([value isKindOfClass:[NSDictionary class]]) {
        if (!representedValues) representedValues = [[NSMutableDictionary alloc] init];
        [representedValues setObject:value forKey:[NSValue valueWithNonretainedObject:component]];
        if ([component isKindOfClass:[NSOutlineView class]]) {
            [(NSOutlineView*)component setDataSource:[LTWCocoaPlatform sharedInstance]];
            //[(NSOutlineView*)component setDelegate:[LTWCocoaPlatform sharedInstance]];
            [(NSOutlineView*)component reloadData]; // NOTE: This must be called AFTER representedValues has been changed.
            success = YES;
        }
    }else if ([value isKindOfClass:[LTWTokens class]]) {
        if ([component isKindOfClass:[LTWTokensView class]]) {
            [(LTWTokensView*)component setTokens:(LTWTokens*)value];
            success = YES;
        }else if ([component isKindOfClass:[LTWOverlayTokensView class]]) {
            [(LTWOverlayTokensView*)component setTokens:(LTWTokens*)value];
            success = YES;
        }else if ([component isKindOfClass:[NSTextField class]]) {
            [(NSTextField*)component setStringValue:[value description]];
            success = YES;
        }
    }
    
    if (!success) {
        NSLog(@"Unable to represent %@ in %@.", value, self);
    }
}


#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    sharedInstance = self;
    
    [window setContentView:mainView];
    NSPoint origin = [window frame].origin;
    NSSize size = [mainView frame].size;
    [window setFrame:NSMakeRect(origin.x, origin.y, size.width, size.height) display:YES animate:YES];
    
    NSOperationQueue *backgroundOperations = [[NSOperationQueue alloc] init];
    
    LTWRemoteDatabase *remoteDatabase = [[LTWRemoteDatabase alloc] init];
    [backgroundOperations addOperation:[[NSInvocationOperation alloc] initWithTarget:remoteDatabase selector:@selector(downloadNewAssessmentFiles) object:nil]];
    
    NSArray *assessmentModes = [[NSArray arrayWithObject:@"No assessment mode"] arrayByAddingObjectsFromArray:[[LTWAssessmentController sharedInstance] assessmentModes]];
    [self setRepresentedValue:assessmentModes forRole:@"assessmentModeSelector"];
}

-(void)loadNewArticles {
    [self setRepresentedValue:[[LTWAssessmentController sharedInstance] articleURLs] forRole:@"articleSelector"];
}

#pragma mark Private

-(void)selectionChangedTo:(id)newSelection forRole:(NSString*)role {
    NSLog(@"%@'s selection changed to %@", role, newSelection);
    
    if ([role isEqual:@"assessmentModeSelector"]) {
        // FIXME: Find out why this doesn't work with autoresizing subviews.
        assessmentMode = newSelection;
        
        NSSize oldSize = [assessmentModeView frame].size;
        
        while ([[assessmentModeView subviews] count] > 0) {
            [[[assessmentModeView subviews] lastObject] removeFromSuperview];
        }
        
        [assessmentModeView addSubview:[assessmentMode mainViewForPlatform:self]];
        
        NSSize size = [mainView convertSize:[[assessmentMode mainViewForPlatform:self] frame].size fromView:assessmentModeView];

        NSRect windowFrame = [[mainView window] frame];
        windowFrame.size = NSMakeSize(windowFrame.size.width + (size.width - oldSize.width), windowFrame.size.height + (size.height - oldSize.height));
        [[mainView window] setFrame:windowFrame display:YES animate:YES];
        
        // NOTE: Should also redo all value-assignments for roles here (so that, for example, if an article is selected in the old assessment mode it will still be selected in the new one).
    }else if ([role isEqual:@"articleSelector"]) {
        LTWArticle *article = [[LTWAssessmentController sharedInstance] articleWithURL:newSelection];
        [self setRepresentedValue:[article tokensForField:@"body"] forRole:@"sourceArticleBody"];
        [self setRepresentedValue:[[article tokensForField:@"title"] description] forRole:@"sourceArticleTitle"];
        [self setRepresentedValue:[[LTWAssessmentController sharedInstance] targetTreeForArticle:article] forRole:@"sourceArticleLinks"];
    }else if ([role isEqual:@"sourceArticleLinks"]) {
        LTWArticle *article = [[LTWAssessmentController sharedInstance] articleWithURL:newSelection];
        [self setRepresentedValue:[article tokensForField:@"body"] forRole:@"targetArticleBody"];
        [self setRepresentedValue:[[article tokensForField:@"title"] description] forRole:@"targetArticleTitle"];
    }
}

-(void)selectionChangedTo:(id)newSelection forComponent:(NSView*)component {
    if (!component) return;
    
    NSString *role = [component roleIfExists];
    if (!role) return;
    
    if (assessmentMode && [self componentWithRole:role inView:[assessmentMode mainViewForPlatform:self]] == component) {
        [assessmentMode selectionChangedTo:newSelection forRole:role];
    }else{
        [self selectionChangedTo:newSelection forRole:role];
    }
}

#pragma mark Miscellaneous

- (id)init {
    if ((self = [super init])) {
        assessmentMode = nil;
        [[LTWAssessmentController sharedInstance] setPlatform:self];
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

-(void)awakeFromNib {
    //[articleSelector setValue:@"articleSelector" forKey:@"role"];
    //[assessmentModeSelector setValue:@"assessmentModeSelector" forKey:@"role"];
}

#pragma mark NSTableViewDataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView*)tableView {
    NSArray *array = [representedValues objectForKey:[NSValue valueWithNonretainedObject:tableView]];
    return array ? [array count] : 0;
}

-(id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)rowIndex {
    NSArray *array = [representedValues objectForKey:[NSValue valueWithNonretainedObject:tableView]];
    return !array ? nil : ([array count] <= rowIndex) ? [array objectAtIndex:rowIndex] : nil;
}

#pragma mark NSTableViewDelegate

-(void)tableViewSelectionDidChange:(NSNotification*)notification {
    NSTableView *sender = [notification object];
    NSUInteger selectedIndex = [sender selectedRow];
    id representedObject = [representedValues objectForKey:[NSValue valueWithNonretainedObject:sender]];
    if (!representedObject || ![representedObject isKindOfClass:[NSArray class]]) return;
    
    NSArray *array = (NSArray*)representedObject;
    if (selectedIndex >= [array count]) return;
    
    [self selectionChangedTo:[array objectAtIndex:selectedIndex] forComponent:sender];
}

#pragma mark NSOutlineViewDataSource

-(id)outlineView:(NSOutlineView*)sender child:(NSInteger)index ofItem:(id)item {
    if (!item) {
        item = [representedValues objectForKey:[NSValue valueWithNonretainedObject:sender]];
    }
    if (!item || ![item isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *dictionary = (NSDictionary*)item;
    
    // NOTE: This relies on [dictionary allKeys] returning the keys in the same order each time (unless the dictionary is mutated, in which case we SHOULD reload the whole thing anyway).
    return [[dictionary allKeys] objectAtIndex:index];
}

-(BOOL)outlineView:(NSOutlineView*)sender isItemExpandable:(id)item {
    if (!item) {
        item = [representedValues objectForKey:[NSValue valueWithNonretainedObject:sender]];
    }
    if (!item || ![item isKindOfClass:[NSDictionary class]]) return NO;
    NSDictionary *dictionary = (NSDictionary*)item;
    
    return [dictionary count] > 0;
}

-(id)outlineView:(NSOutlineView*)sender objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item {
    return item;
}

-(BOOL)outlineView:(NSOutlineView*)sender numberOfChildrenOfItem:(id)item {
    if (!item) {
        item = [representedValues objectForKey:[NSValue valueWithNonretainedObject:sender]];
    }
    if (!item || ![item isKindOfClass:[NSDictionary class]]) return 0;
    NSDictionary *dictionary = (NSDictionary*)item;
    
    return [dictionary count];
}

#pragma mark NSOutlineViewDelegate

#pragma mark NSPopUpButton actions

-(IBAction)popUpButtonSelectionDidChange:(NSPopUpButton*)sender {
    NSUInteger selectedIndex = [[sender objectValue] intValue];
    id representedObject = [representedValues objectForKey:[NSValue valueWithNonretainedObject:sender]];
    if (!representedObject || ![representedObject isKindOfClass:[NSArray class]]) return;
    
    NSArray *array = (NSArray*)representedObject;
    if (selectedIndex >= [array count]) return;
    
    [self selectionChangedTo:[array objectAtIndex:selectedIndex] forComponent:sender];
}

@end

@implementation NSView (RoleStorage)

static NSMutableDictionary *roles = nil;

-(void)setValue:(id)value forUndefinedKey:(NSString*)key {
    if (!roles) roles = [[NSMutableDictionary alloc] init];
    if (![key isEqual:@"role"]) {
        [super setValue:value forUndefinedKey:key];
        return;
    }
    
    [roles setObject:value forKey:[NSValue valueWithNonretainedObject:self]];
}

-(id)valueForUndefinedKey:(NSString*)key {
    NSString *role = [self roleIfExists];
    return (role && [key isEqual:@"role"]) ? role : [super valueForUndefinedKey:key];
}

-(id)roleIfExists {
    if (!roles) roles = [[NSMutableDictionary alloc] init];
    return [roles objectForKey:[NSValue valueWithNonretainedObject:self]];
}

@end
#endif
