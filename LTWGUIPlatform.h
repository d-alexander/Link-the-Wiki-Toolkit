//
//  LTWGUIPlatform.h
//  LTWToolkit
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 The protocol LTWGUIPlatform defines the methods that a platform-specific GUI adapter for LTWAssessmentTool (and later, all of LTWToolkit) should implement.
 Eventually, almost all of the platform-specific code for each GUI platform should be in a single class that conforms to this protocol. This is tricky because application startup needs to begin with a main() function, in which both the GUI and other components will have to be initialised. Furthermore, platforms such as Cocoa have non-code files that play a role in application startup, such as MainMenu.xib.
 Currently, the protocol is written to support only the Cocoa platform; some of the parameter/return types will need to be changed to more generic ones to allow other platforms.
 In Cocoa, the platfom class will also act as the application delegate. This will make it easier to keep all of the platform-specific code inside the platform class. However, care must be exercised to ensure that most of the logic related to handling an event is done in one of the methods that this protocol declares, rather than a delegate method. This will keep the interface clean and make refactoring easier later on.
 */
@protocol LTWGUIPlatform <NSObject>

+(id <LTWGUIPlatform>)sharedInstance;
-(NSView*)mainView;
-(NSView*)componentWithRole:(NSString*)role inView:(NSView*)view;


@end
