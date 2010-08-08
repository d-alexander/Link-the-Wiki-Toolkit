//
//  LTWTokenProcessor.h
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LTWPythonUtils.h"
#import "LTWSearch.h"


@interface LTWTokenProcessor : NSObject <LTWPythonImplementation, LTWSearchRequester> {
	PyObject *implementation;
    NSString *displayName;
}

@property (readonly) NSString *displayName;

-(id)initWithImplementationCode:(NSString*)pythonCode;
-(void)setImplementationCode:(NSString*)pythonCode;
-(NSArray*)initialSearches;
-(NSArray*)handleSearchResult:(LTWTokens*)result forSearch:(LTWSearch*)search;

@end
