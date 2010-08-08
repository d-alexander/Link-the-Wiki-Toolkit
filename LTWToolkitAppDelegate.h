//
//  LTWToolkitAppDelegate.h
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __COCOTRON__
@interface LTWToolkitAppDelegate : NSObject {
#else
@interface LTWToolkitAppDelegate : NSObject <NSApplicationDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource> {  
#endif
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
@property (readonly) NSTextField *articleURLField; // TEMP -- So that LTWCorpus can add new articles on its own.

@end
