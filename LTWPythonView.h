//
//  LTWPythonView.h
//  LTWToolkit
//
//  Created by David Alexander on 28/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWPythonUtils.h"

@interface LTWPythonView : NSTextView {
	IBOutlet id <LTWPythonImplementation> pythonComponent;
}

-(IBAction)compile:(id)sender;

@end
