//
//  LTWTokenProcessor.m
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWTokenProcessor.h"


@implementation LTWTokenProcessor

@synthesize displayName;

-(id)initWithImplementationCode:(NSString*)pythonCode {
	if (self = [super init]) {
		if (pythonCode) {
			self->implementation = [LTWPythonUtils compilePythonObjectFromCode:pythonCode];
			self->displayName = @"(token-processor)";
		}
	}
	return self;
}

-(void)setImplementationCode:(NSString*)pythonCode {
	Py_XDECREF(self->implementation);
	self->implementation = [LTWPythonUtils compilePythonObjectFromCode:pythonCode];
}

-(NSArray*)initialSearches {
    // This gets an array of "searches" that the Token Processor wants to get the results of. It should only be called once, as the Token Processor may use it for other initialisation tasks.
    
    NSArray *searches = nil;
    [LTWPythonUtils callMethod:"get_initial_searches" onPythonObject:self->implementation withArgument:nil returnFormat:"O", &searches];
    return searches;
}

-(NSArray*)handleSearchResult:(LTWTokens*)result forSearch:(id/*should be LTWSearch*/)search {
    PyObject *arg = nil;// should be [LTWPythonUtils pythonTupleWithObjects:result, search, nil];
    
    NSArray *newSearches = nil;
    [LTWPythonUtils callMethod:"handle_search_result" onPythonObject:self->implementation withArgument:arg returnFormat:"O", &newSearches];
    
    return newSearches;
}

@end
