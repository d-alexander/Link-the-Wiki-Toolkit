//
//  LTWPythonDocument.h
//  LTWToolkit
//
//  Created by David Alexander on 28/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWPythonUtils.h"

#ifdef __COCOTRON__
@interface LTWPythonDocument : NSDocument {
#else
@interface LTWPythonDocument : NSDocument <NSTextViewDelegate> {
#endif
	IBOutlet NSTextView *codeView;
	id <LTWPythonImplementation> pythonComponent;
	NSAttributedString *codeAttributedString;
}

-(IBAction)compileAsCorpus:(id)sender;
-(IBAction)compileAsTokenProcessor:(id)sender;

@end
