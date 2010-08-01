//
//  LTWPythonView.m
//  LTWToolkit
//
//  Created by David Alexander on 28/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWPythonView.h"

#import "LTWCorpus.h"


@implementation LTWPythonView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		// TEMP
		self->pythonComponent = [[LTWCorpus alloc] initWithImplementationCode:nil];
    }
    return self;
}

-(id)init {
	self = [super init];
    if (self) {
		// TEMP
		self->pythonComponent = [[LTWCorpus alloc] initWithImplementationCode:nil];
    }
    return self;
}

-(IBAction)compile:(id)sender {
	if (self->pythonComponent) {
		[self->pythonComponent setImplementationCode:[[self textStorage] string]];
	}
}

@end
