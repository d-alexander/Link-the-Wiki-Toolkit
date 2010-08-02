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
-(NSString*)displayName;

@end

@interface LTWPythonUtils : NSObject {

}

typedef struct LTWPyToken LTWPyToken;
typedef struct LTWPyTokenIterator LTWPyTokenIterator;

+(LTWPyTokenIterator*)pythonIteratorForTokens:(LTWTokens*)tokens;
+(PyObject*)compilePythonObjectFromCode:(NSString*)code;
+(void)callMethod:(char*)methodName onPythonObject:(PyObject*)pythonObject withArgument:(PyObject*)argument returnFormat:(const char*)returnFormat,...;

@end
