//
//  LTWToolkitAppDelegate.h
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LTWToolkitAppDelegate : NSObject <NSApplicationDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource> {
    NSWindow *window;
	IBOutlet NSTextField *articleURLField;
	NSMutableArray *corpora;
    NSMutableArray *tokenProcessors;
    NSMutableArray *articles;
	IBOutlet NSOutlineView *articleSelectionView;
}

-(IBAction)loadArticle:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (readonly) NSMutableArray *corpora;
@property (readonly) NSMutableArray *tokenProcessors;

@end
