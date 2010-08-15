//
//  LTWCocoaPlatform.h
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LTWGUIPlatform.h"
#import "LTWAssessmentMode.h"

#ifdef __COCOTRON__
@interface LTWCocoaPlatform : NSObject <LTWGUIPlatform> {
#else
@interface LTWCocoaPlatform : NSObject <LTWGUIPlatform, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate> {
#endif
    IBOutlet NSWindow *window;
    IBOutlet NSView *mainView;
    id <LTWAssessmentMode> assessmentMode;
    IBOutlet NSView *assessmentModeView;
    
    // Role outlets:
    IBOutlet NSView *assessmentModeSelector;
    IBOutlet NSView *articleSelector;
}

@property (assign) NSWindow *window;

+(LTWCocoaPlatform*)sharedInstance;

-(NSInteger)numberOfRowsInTableView:(NSTableView*)tableView;
-(id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)rowIndex;

@end

@interface NSView (RoleStorage)

-(void)setValue:(id)value forUndefinedKey:(NSString*)key;
-(id)valueForUndefinedKey:(NSString*)key;
-(id)roleIfExists;
-(void)setRepresentedValue:(id)value;

@end