//
//  LTWPythonUtils.h
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#ifdef __COCOTRON__
    #import <Python-Windows/Python.h>
#else
    #import <Python/Python.h>
#endif

#import "LTWTokens.h"

@protocol LTWPythonImplementation <NSObject>

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
+(void)callMethod:(char*)methodName onPythonObject:(PyObject*)pythonObject withArgument:(PyObject*)argument depythonise:(BOOL)depythonise returnFormat:(const char*)returnFormat,...;
+(PyObject*)pythonTupleWithObjects:(id)firstObject,...;

+(BOOL)depythoniseObject:(PyObject*)object intoPointer:(void**)pointer;
+(PyObject*)pythoniseObject:(id)object;

@end
