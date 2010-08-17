//
//  LTWCocoaPlatform.m
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

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


#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    sharedInstance = self;
    
    // TEMP
    [[LTWRemoteDatabase alloc] init];
    
    [window setContentView:mainView];
    NSPoint origin = [window frame].origin;
    NSSize size = [mainView frame].size;
    [window setFrame:NSMakeRect(origin.x, origin.y, size.width, size.height) display:YES animate:YES];
    
    [[self componentWithRole:@"articleSelector" inView:[self mainView]] setRepresentedValue:[[LTWAssessmentController sharedInstance] articleURLs]];
    
    NSArray *assessmentModes = [[NSArray arrayWithObject:@"No assessment mode"] arrayByAddingObjectsFromArray:[[LTWAssessmentController sharedInstance] assessmentModes]];
    [[self componentWithRole:@"assessmentModeSelector" inView:[self mainView]] setRepresentedValue:assessmentModes];
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
    }else if ([role isEqual:@"articleSelector"]) {
        [[self componentWithRole:@"sourceArticleBody" inView:[assessmentMode mainViewForPlatform:self]] setRepresentedValue:[[[LTWAssessmentController sharedInstance] articleWithURL:newSelection] tokensForField:@"body"]];
        [[self componentWithRole:@"sourceArticleTitle" inView:[assessmentMode mainViewForPlatform:self]] setRepresentedValue:[[[[LTWAssessmentController sharedInstance] articleWithURL:newSelection] tokensForField:@"title"] description]];
    }else if ([role isEqual:@"sourceArticleLinks"]) {
        [[self componentWithRole:@"targetArticleBody" inView:[assessmentMode mainViewForPlatform:self]] setRepresentedValue:[[[LTWAssessmentController sharedInstance] articleWithURL:newSelection] tokensForField:@"body"]];
        [[self componentWithRole:@"targetArticleTitle" inView:[assessmentMode mainViewForPlatform:self]] setRepresentedValue:[[[[LTWAssessmentController sharedInstance] articleWithURL:newSelection] tokensForField:@"title"] description]];
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

static NSMutableDictionary *representedValues = nil; // Stores data that is currently being shown.

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

-(void)setRepresentedValue:(id)value {
    // This tries to "translate" the given value into something that can be displayed by the view.
    
    if ([value isKindOfClass:[NSArray class]]) {
        if (!representedValues) representedValues = [[NSMutableDictionary alloc] init];
        [representedValues setObject:value forKey:[NSValue valueWithNonretainedObject:self]];
        if ([self isKindOfClass:[NSPopUpButton class]]) {
            NSPopUpButton *button = (NSPopUpButton*)self;
            [button removeAllItems];
            for (id entry in (NSArray*)value) {
                [button addItemWithTitle:[entry description]];
            }
            [button setAction:@selector(popUpButtonSelectionDidChange:)];
            [button setTarget:[LTWCocoaPlatform sharedInstance]];
        }else if ([self isKindOfClass:[NSTableView class]]) {
            [(NSTableView*)self setDataSource:[LTWCocoaPlatform sharedInstance]];
            [(NSTableView*)self setDelegate:[LTWCocoaPlatform sharedInstance]];
            [(NSTableView*)self reloadData]; // NOTE: This must be called AFTER representedValues has been changed.
        }
    }else if ([value isKindOfClass:[LTWTokens class]]) {
        if ([self isKindOfClass:[LTWTokensView class]]) {
            [(LTWTokensView*)self setTokens:(LTWTokens*)value];
        }else if ([self isKindOfClass:[LTWOverlayTokensView class]]) {
            [(LTWOverlayTokensView*)self setTokens:(LTWTokens*)value];
        }
    }else{
        NSLog(@"Unable to represent %@ in %@.", value, self);
    }
}

@end
