//
//  LTWTokenProcessor.m
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWTokenProcessor.h"

#import "LTWSearch.h"

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

/*
 NOTE: Still having some trouble calling Python methods with no arguments, so currently passing dummy arguments in the two methods below. Need to find out how to do it properly!
 */

-(NSArray*)initialSearches {
    // This gets an array of "searches" that the Token Processor wants to get the results of. It should only be called once, as the Token Processor may use it for other initialisation tasks.
    
    PyObject *obj = NULL;
    [LTWPythonUtils callMethod:"get_initial_searches" onPythonObject:self->implementation withArgument:NULL depythonise:NO returnFormat:"O", &obj, NULL];
    
    NSArray *searches = [LTWSearch parsePythonSearchArray:obj requester:self];
    
    return searches;
}

-(NSArray*)handleSearchResult:(LTWTokens*)result forSearch:(LTWSearch*)search {
    // NOT CURRENTLY IN USE. See LTWSearch.
    
    return nil;
}

@end
