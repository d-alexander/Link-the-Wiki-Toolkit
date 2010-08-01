//
//  LTWPythonUtils.h
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Python/Python.h>

#import "LTWTokens.h"

@protocol LTWPythonImplementation

-(id)initWithImplementationCode:(NSString*)pythonCode;
-(void)setImplementationCode:(NSString*)pythonCode;

@end

@interface LTWPythonUtils : NSObject {

}

+(PyObject*)compilePythonObjectFromCode:(NSString*)code;
+(NSDictionary*)callMethod:(const char*)methodName onPythonObject:(PyObject*)pythonObject withTokens:(LTWTokens*)tokens;

@end
