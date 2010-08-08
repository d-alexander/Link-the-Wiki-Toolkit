//
//  LTWPythonUtils.m
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWPythonUtils.h"

#import "LTWParser.h"


@implementation LTWPythonUtils

#pragma mark LTWPyToken

/*
 NOTE: A list of string methods is here: http://docs.python.org/release/2.5.2/lib/string-methods.html
 
 Some of the more important ones to implement:
	endswith/startswith
	find/index
	isalnum/isalpha/isdigit/islower/isspace/istitle/isupper
	join/partition
	lower
	(There should also be a method to convert tokens to "real" Python strings -- perhaps implicitly on assignment.)
	In fact, perhaps Token should just be a "Sequence type" (see http://docs.python.org/c-api/sequence.html )
 
 Also:
	Regardless of the internal implementation, an iterator to a token should always be reconstructable from the token itself. That way, the Python code never has to explicitly care about iterators at all -- it can return tokens instead.
	XML tokens should be comparable with ordinary Python strings in a smart way -- a Python string representing an XML tag with some or all of its attributes specified should match a token which has the same tagname and at least those attributes. Attribute values may or may not be specified in the string, but if they are, they should be considered restrictive. Tagnames and attribute names are case-insensitive. (Note that this is not *all* you might want to do with an XML tag -- you might want to get the value of an attribute -- but this seems like the most useful thing for parsing documents where XML tags are not a primary feature but rather serve as delimiters.)
 */

struct LTWPyToken {
	PyObject_HEAD
	NSString *string;
    LTWTokens *tokens;
	NSDictionary *extraInfo;
	NSRange range;
	NSUInteger index;
};

static PyTypeObject LTWPyTokenType; // forward declaration.

static PyObject *LTWPyToken_Length(LTWPyToken *obj, PyObject *args) {
	return PyInt_FromLong(obj->range.length);
}

static void LTWPyToken_dealloc(LTWPyToken* self) {
    //Py_TYPE(self)->tp_free((PyObject*)self);
}

static PyObject *LTWPyToken_repr(LTWPyToken *obj) {
	if (obj->range.location == NSNotFound) return Py_BuildValue("s", "(token not found)");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSRange entireRange = obj->range;
	NSNumber *tagRemainderLength = [obj->extraInfo objectForKey:@"tagRemainderLength"];
	if (tagRemainderLength) entireRange.length += [tagRemainderLength intValue];
	const char *token_cstr = [[obj->string substringWithRange:entireRange] UTF8String];
	PyObject *str = Py_BuildValue("s", token_cstr);
	[pool drain];
	return str;
}

BOOL LTWPyToken_simpleCompare(PyObject *o1, PyObject *o2) {
    PyObject *s1 = PyObject_Str(o1);
    PyObject *s2 = PyObject_Str(o2);
    int result = PyObject_RichCompareBool(s1, s2, Py_LE);
    Py_DECREF(s1);
    Py_DECREF(s2);
    return result == 1;
}

NSInteger LTWPyToken_stringRangeCompare(NSString *s1, NSRange r1, NSString *s2, NSRange r2) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *subS2 = [s2 substringWithRange:r2];
    NSComparisonResult result = [s1 compare:subS2 options:0 range:r1];
    [pool drain];
    return (NSInteger)((result == NSOrderedSame) ? 0 : (result == NSOrderedAscending) ? -1 : 1);
}
                                        
static BOOL LTWPyToken_lessorequal(PyObject *left, PyObject *right) {
	static LTWParser *parser = nil;
	if (!parser) parser = [[LTWParser alloc] init];
	static NSMutableDictionary *otherExtraInfo = nil;
	if (!otherExtraInfo) otherExtraInfo = [[NSMutableDictionary alloc] init];
	
	if (PyObject_IsInstance(left, (PyObject*)&LTWPyTokenType) && PyObject_IsInstance(right, (PyObject*)&LTWPyTokenType)) {
		return LTWPyToken_simpleCompare(left, right);
	}else{
		LTWPyToken *token = PyObject_IsInstance(left, (PyObject*)&LTWPyTokenType) ? (LTWPyToken*)left : (LTWPyToken*)right;
		if (!PyObject_IsInstance((PyObject*)token, (PyObject*)&LTWPyTokenType)) return NO; // this shouldn't happen!
		
		PyObject *other = ((PyObject*)token == left) ? right : left;
		PyObject *otherString = PyObject_Str(other);
		NSString *otherNSString = [[NSString alloc] initWithUTF8String:PyString_AsString(otherString)];
		
		[parser setDocumentText:otherNSString];
		NSRange otherRange = [parser getNextTokenWithExtraInfo:otherExtraInfo];
		
		if (otherRange.location == NSNotFound) return LTWPyToken_simpleCompare(left, right);
		
		NSInteger result = LTWPyToken_stringRangeCompare(token->string, token->range, otherNSString, otherRange);
		if ((PyObject*)token == right) result = -result;
		if (result != 0) return (result < 0);
		
		if ([token->extraInfo objectForKey:@"isXML"] != nil && [otherExtraInfo objectForKey:@"isXML"] == nil) {
			result = -1;
		}else if ([token->extraInfo objectForKey:@"isXML"] == nil && [otherExtraInfo objectForKey:@"isXML"] != nil) {
			result = 1;
		}else{
			result = 0;
		}
		if ((PyObject*)token == right) result = -result;
		if (result != 0) return (result < 0);
		
		// At this point, left and right are either both XML or both not XML. If not XML, we can't do any further comparison.
		if ([token->extraInfo objectForKey:@"isXML"] == nil && [otherExtraInfo objectForKey:@"isXML"] == nil) return YES;
		
		if ([token->extraInfo objectForKey:@"isEndTag"] == nil && [otherExtraInfo objectForKey:@"isEndTag"] != nil) {
			result = -1;
		}else if ([token->extraInfo objectForKey:@"isEndTag"] != nil && [otherExtraInfo objectForKey:@"isEndTag"] == nil) {
			result = 1;
		}else{
			result = 0;
		}
		if ((PyObject*)token == right) result = -result;
		if (result != 0) return (result < 0);
		
		// At this point, left and right are either both end-tags or both not end-tags. If both end-tags, we can't do any further comparison so we should say they're equal.
		if ([token->extraInfo objectForKey:@"isEndTag"] != nil && [otherExtraInfo objectForKey:@"isEndTag"] != nil) return YES;
		
		result = 0;
		for (NSString *key in otherExtraInfo) {
			if (![key hasPrefix:@"attribute"]) continue;
			
			NSString *otherValue = [otherExtraInfo objectForKey:key];
			NSString *tokenValue = [token->extraInfo objectForKey:key];
			
			if (tokenValue == nil || ![tokenValue isEqual:otherValue]) {
				result = -1;
				break;
			}
		}
		if ((PyObject*)token == right) result = -result;
		return (result <= 0);
	}
}

static PyObject *LTWPyToken_richcmp(PyObject *left, PyObject *right, int operation) {
	// NOTE: This is a *temporary* inefficient implementation in which everything is based on <=
	BOOL result = NO;
	switch (operation) {
		case Py_LT:
			if (LTWPyToken_lessorequal(left, right) && !LTWPyToken_lessorequal(right, left)) result = YES;
			break;
		case Py_LE:
			if (LTWPyToken_lessorequal(left, right)) result = YES;
			break;
		case Py_GT:
			if (LTWPyToken_lessorequal(right, left) && !LTWPyToken_lessorequal(left, right)) result = YES;
			break;
		case Py_GE:
			if (LTWPyToken_lessorequal(right, left)) result = YES;
			break;
		case Py_EQ:
			if (LTWPyToken_lessorequal(left, right) && LTWPyToken_lessorequal(right, left)) result = YES;
			break;
		case Py_NE:
			if (LTWPyToken_lessorequal(left, right) ^ LTWPyToken_lessorequal(right, left)) result = YES;
			break;
	}
	
	if (result) {
		Py_RETURN_TRUE;
	}else{
		Py_RETURN_FALSE;
	}
}


static PyMethodDef LTWPyTokenMethods[] = {
	{NULL}
};

static PySequenceMethods LTWPyTokenSequenceMethods = {
	0,0,0,0,0,0,0,0,0,0
};

#pragma mark LTWPyTokenIterator

struct LTWPyTokenIterator {
	PyObject_HEAD
	LTWTokens *tokens;
	NSUInteger currentTokenIndex;
};

LTWPyTokenIterator *LTWPyTokenIterator_GetIter(LTWPyTokenIterator *obj) {
	Py_INCREF(obj);
	return obj;
}

PyObject *LTWPyTokenIterator_Next(LTWPyTokenIterator *obj) {
	LTWPyToken *token = PyObject_New(LTWPyToken, &LTWPyTokenType);
	
	token->range = [obj->tokens rangeOfTokenAtIndex:obj->currentTokenIndex];
	token->string = [obj->tokens _text];
	token->extraInfo = [obj->tokens extraInfoForTokenAtIndex:obj->currentTokenIndex];
	token->index = obj->currentTokenIndex;
    token->tokens = obj->tokens;
	
	if (token->range.location == NSNotFound) {
		PyErr_SetNone(PyExc_StopIteration);
		return NULL;
	}
	
	obj->currentTokenIndex++;
	
	return (PyObject*)token;
}

static void LTWPyTokenIterator_dealloc(LTWPyToken* self) {
    //Py_TYPE(self)->tp_free((PyObject*)self);
}

static PyMethodDef LTWPyTokenIteratorMethods[] = {
	{NULL}
};

static PyTypeObject LTWPyTokenIteratorType = {
    PyObject_HEAD_INIT(NULL)
    0,
    "ltw.TokenIterator",
	sizeof(LTWPyTokenIterator),
	0,
	(destructor)LTWPyTokenIterator_dealloc,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    Py_TPFLAGS_DEFAULT,
    "LTW Token Iterator",
	0,0,0,0,
	(getiterfunc)LTWPyTokenIterator_GetIter,
	(iternextfunc)LTWPyTokenIterator_Next,
	LTWPyTokenIteratorMethods,
};

#pragma mark LTWPyModule

PyObject* LTWPyModuleTokensFromString(PyObject *self, PyObject *args) {
    char *str;    
    if (!PyArg_ParseTuple(args, "s", &str)) Py_RETURN_NONE;

    LTWTokens *tokens = [[LTWTokens alloc] initWithXML:[NSString stringWithUTF8String:str]];
    
    LTWPyToken *firstToken = PyObject_New(LTWPyToken, &LTWPyTokenType), *lastToken = PyObject_New(LTWPyToken, &LTWPyTokenType);
    firstToken->range = [tokens rangeOfTokenAtIndex:0];
	firstToken->string = [tokens _text];
	firstToken->extraInfo = [tokens extraInfoForTokenAtIndex:0];
	firstToken->index = 0;
    firstToken->tokens = tokens;
    
    lastToken->range = [tokens rangeOfTokenAtIndex:[tokens count]-1];
	lastToken->string = [tokens _text];
	lastToken->extraInfo = [tokens extraInfoForTokenAtIndex:[tokens count]-1];
	lastToken->index = [tokens count]-1;
    lastToken->tokens = tokens;
    
    return Py_BuildValue("OO", firstToken, lastToken);
}

PyObject* LTWPyModuleTagRange(PyObject *self, PyObject *args) {
    PyObject *pyTokens = NULL, *pyTagName = NULL, *pyTagValue = NULL;
    
    if (!PyArg_ParseTuple(args, "OOO", &pyTokens, &pyTagName, &pyTagValue)) Py_RETURN_NONE;
    
    LTWTokens *tokens = nil;
    NSString *tagName = nil;
    id tagValue = nil;
    
    if (![LTWPythonUtils depythoniseObject:pyTokens intoPointer:(void**)&tokens]) return nil;
    if (![LTWPythonUtils depythoniseObject:pyTagName intoPointer:(void**)&tagName]) return nil;
    if (![LTWPythonUtils depythoniseObject:pyTagValue intoPointer:(void**)&tagValue]) return nil;
    
    [tokens addTag:[[LTWTokenTag alloc] initWithName:tagName value:tagValue]];
    
    return Py_BuildValue("i", 0);
}

static PyMethodDef LTWPyModuleMethods[] = {
    {"tokens_from_string", (PyCFunction)LTWPyModuleTokensFromString, METH_VARARGS,
        "Convert a string to a sequence of tokens, and returns a tuple consisting of the first and last token in the sequence."},
    {"tag_range", (PyCFunction)LTWPyModuleTagRange, METH_VARARGS, "Tag the given token-range (either a token iterator or a pair of tokens) with the given tagname and value."},
	{NULL}
};

PyMODINIT_FUNC LTWPyModuleInit() {
	PyObject *module = Py_InitModule3("ltw", LTWPyModuleMethods, "LTW Module");
	
	LTWPyTokenType = (PyTypeObject){
		PyObject_HEAD_INIT(NULL)
		0,
		"ltw.Token",
		sizeof(LTWPyToken),
		0,
		(destructor)LTWPyToken_dealloc,
		0,0,0,0,
		(reprfunc)LTWPyToken_repr,
		0,
		&LTWPyTokenSequenceMethods,
		0,0,0,0,0,0,0,
		Py_TPFLAGS_DEFAULT,
		"LTW Token",
		0,0,
		(richcmpfunc)LTWPyToken_richcmp,
		0,0,0,
		LTWPyTokenMethods,
	};
	
	LTWPyTokenType.tp_new = PyType_GenericNew;
	PyType_Ready(&LTWPyTokenType);
	Py_INCREF(&LTWPyTokenType);
	PyModule_AddObject(module, "Token", (PyObject*)&LTWPyTokenType);
	
	LTWPyTokenIteratorType.tp_new = PyType_GenericNew;
	PyType_Ready(&LTWPyTokenIteratorType);
	Py_INCREF(&LTWPyTokenIteratorType);
	PyModule_AddObject(module, "TokenIterator", (PyObject*)&LTWPyTokenIteratorType);
}

#pragma mark Objective-C

+(LTWPyTokenIterator*)pythonIteratorForTokens:(LTWTokens*)tokens {
	LTWPyTokenIterator *iterator = (LTWPyTokenIterator*)_PyObject_New(&LTWPyTokenIteratorType);

	iterator->tokens = tokens;
	iterator->currentTokenIndex = 0;
	return iterator;
}

+(void)initialize {
	//PyImport_AppendInittab("ltw", LTWPyModuleInit);
	Py_Initialize();
	LTWPyModuleInit();
}

+(PyObject*)compilePythonObjectFromCode:(NSString*)code {
	const char *codeCString = [code UTF8String];

	PyObject *module = PyImport_AddModule("__main__");
	PyObject *dict = PyModule_GetDict(module);
	if (!PyRun_StringFlags(codeCString, Py_file_input, dict, dict, 0)) {
		PyErr_Print();
	}
	PyObject *result = PyRun_StringFlags("the_corpus", Py_eval_input, dict, dict, 0);
	if (!result) {
		PyErr_Print();
	}
	return result;
}

// Returns true if the depythonised object is an Objective-C object, and therefore doesn't need to be wrapped in NSValue before inserting into a collection.
// NOTE: If the object is an Objective-C object, an owning reference will not be returned. The caller should either retain it directly or insert it into a collection.
+(BOOL)depythoniseObject:(PyObject*)object intoPointer:(void**)pointer {
    LTWPyToken *firstToken = NULL, *lastToken = NULL;
    char *str;
    
    if (PyArg_ParseTuple(object, "O!O!", &LTWPyTokenType, (PyObject**)&firstToken, &LTWPyTokenType, (PyObject**)&lastToken) && firstToken->tokens == lastToken->tokens) {
        if (firstToken->index > lastToken->index) {
            LTWPyToken *temp = firstToken;
            firstToken = lastToken;
            lastToken = temp;
        }
        
        LTWTokens *tokens = [firstToken->tokens tokensFromIndex:firstToken->index toIndex:lastToken->index propagateTags:YES];
        
        *pointer = tokens;
        return YES;
    }else if (PyArg_Parse(object, "s", &str)) {
        *pointer = [NSString stringWithUTF8String:str];
        return YES;
    }else if (PyMapping_Check(object)) {
        NSUInteger dictionarySize = PyMapping_Size(object);
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionarySize]; 
        PyObject *dictionaryItems = PyMapping_Items(object);
        for (NSUInteger i=0; i<dictionarySize; i++) {
            PyObject *keyValueTuple = PySequence_GetItem(dictionaryItems, i);
            PyObject *key = NULL, *value = NULL;
            PyArg_ParseTuple(keyValueTuple, "OO", &key, &value);
            
            void *depythonisedKey = NULL, *depythonisedValue = NULL;
            BOOL isObjC = [LTWPythonUtils depythoniseObject:key intoPointer:&depythonisedKey];
            if (!isObjC) depythonisedKey = [NSValue valueWithPointer:depythonisedKey];
            isObjC = [LTWPythonUtils depythoniseObject:value intoPointer:&depythonisedValue];
            if (!isObjC) depythonisedValue = [NSValue valueWithPointer:depythonisedValue];
            
            [dictionary setObject:depythonisedValue forKey:depythonisedKey];
        }
        *pointer = [dictionary autorelease];
        return YES;
    }else if (PySequence_Check(object)) {
        NSUInteger sequenceLength = PySequence_Length(object);
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:sequenceLength];
        for (NSUInteger i=0; i<sequenceLength; i++) {
            PyObject *item = PySequence_GetItem(object, i);
            void *depythonisedItem = nil;
            if (item == object) continue; // For some reason, trying to get the first "item" of a string returns the string itself.
            BOOL isObjC = [LTWPythonUtils depythoniseObject:item intoPointer:&depythonisedItem];
            if (!isObjC) depythonisedItem = [NSValue valueWithPointer:depythonisedItem];
            [array addObject:(id)depythonisedItem];
        }
        *pointer = [array autorelease];
        return YES;
    }
    
    return NO;
}

+(PyObject*)pythoniseObject:(id)object {
    if (!object) {
        Py_RETURN_NONE;
    }else if ([object isKindOfClass:[LTWTokens class]]) {
        return (PyObject*)[LTWPythonUtils pythonIteratorForTokens:(LTWTokens*)object];
    }else{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        const char *descriptionCStr = [[object description] UTF8String];
        PyObject *descriptionPythonString = Py_BuildValue("s", descriptionCStr);
        [pool drain];
        return descriptionPythonString;
    }
    return NULL;
}

// Calls the method given by methodName on the Python object given by pythonObject.
// The argument parameter should be either a single Python object or a tuple of Python objects to be passed to the method.
// The returnFormat parameter is a Python format string describing the expected return value(s).
// The arguments following returnFormat should be pointers to variables of the appropriate types to hold references to the returned objects. However, some Python types are automatically converted into Objective-C objects: strings are converted to NSStrings, other sequence types are converted to NSArrays, and a tuple of tokens (where both tokens are within the same LTWTokens object) is converted to LTWTokenRanges.
// When an Objective-C object is returned, the caller receives an owning reference to it.
+(void)callMethod:(char*)methodName onPythonObject:(PyObject*)pythonObject withArgument:(PyObject*)argument depythonise:(BOOL)depythonise returnFormat:(const char*)returnFormat,... {
    
    PyObject *result;
    if (!argument) {
        result = PyObject_CallMethod(pythonObject, methodName, NULL);
    }else{
        result = PyObject_CallMethod(pythonObject, methodName, "O", argument);
    }
    
    if (!result) return;
    
    va_list vlParse, vlDepythonise;
    va_start(vlDepythonise, returnFormat);
    va_copy(vlParse, vlDepythonise);
    if (!PyArg_VaParse(result, returnFormat, vlParse)) {
        va_end(vlParse);
        va_copy(vlParse, vlDepythonise);
        result = Py_BuildValue("(O)", result);
        if (!PyArg_VaParse(result, returnFormat, vlParse)) goto cleanup;
    }
    
    if (depythonise) {
        for (void *p = va_arg(vlDepythonise, void*); p != NULL; p = va_arg(vlDepythonise, void*)) {
            BOOL isObjC = [LTWPythonUtils depythoniseObject:*(PyObject**)p intoPointer:(void**)p];
            if (isObjC) [*(id*)p retain];
        }
    }
    
cleanup:
    va_end(vlParse);
    va_end(vlDepythonise);
    
}

// This method takes a list of Objective-C objects, turns them into the appropriate Python objects (returning NULL and printing an error if this is not possible) and puts the objects into a tuple.
// The list of objects should be terminated by nil. For an empty tuple, make nil the first object in the list.
+(PyObject*)pythonTupleWithObjects:(id)firstObject,... {
    va_list vlCountObjects, vlPythoniseObjects;
    
    if (!firstObject) {
        // Do we need this, or will PyTuple_New accept 0 as a size?
        return Py_BuildValue("()");
    }
    
    va_start(vlCountObjects, firstObject);
    va_copy(vlPythoniseObjects, vlCountObjects);
    
    NSUInteger numObjects = 0;
    for (id obj = firstObject; obj != nil; obj = va_arg(vlCountObjects, id)) numObjects++;
    va_end(vlCountObjects);
    
    PyObject *tuple = PyTuple_New(numObjects);
    int pos = 0;
    for (id obj = firstObject; obj != nil; obj = va_arg(vlPythoniseObjects, id), pos++) {
        PyObject *pythonisedObject = [LTWPythonUtils pythoniseObject:obj];
        if (!pythonisedObject) return NULL; // NOTE: Should release held references here.
        PyTuple_SET_ITEM(tuple, pos, pythonisedObject);
    }
    va_end(vlPythoniseObjects);
    
    return tuple;
}

@end
