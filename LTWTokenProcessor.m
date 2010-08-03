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
    
    NSArray *ranges = nil;
    [LTWPythonUtils callMethod:"get_initial_searches" onPythonObject:self->implementation withArgument:(PyObject*)[LTWPythonUtils pythonIteratorForTokens:[[LTWTokens alloc] initWithXML:@"TESTING"]] returnFormat:"O", &ranges, NULL];
    NSMutableArray *searches = [NSMutableArray arrayWithCapacity:[ranges count]];
    for (NSValue *rangeValue in ranges) {
        LTWTokenRange *range = [rangeValue pointerValue];
        [searches addObject:[[LTWSearch alloc] initWithTokens:[range->tokens tokensFromIndex:range->firstToken toIndex:range->lastToken propagateTags:YES] requester:self]];
    }
    return searches;
}

-(NSArray*)handleSearchResult:(LTWTokens*)result forSearch:(LTWSearch*)search {
    PyObject *arg = nil;// should be [LTWPythonUtils pythonTupleWithObjects:result, search, nil];
    
    NSArray *newSearches = nil;
    [LTWPythonUtils callMethod:"handle_search_result" onPythonObject:self->implementation withArgument:arg returnFormat:"O", &newSearches];
    
    return newSearches;
}

@end
