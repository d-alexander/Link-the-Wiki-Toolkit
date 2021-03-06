//
//  LTWCorpus.h
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWPythonUtils.h"
#import "LTWArticle.h"


@interface LTWCorpus : NSObject <LTWPythonImplementation> {
	PyObject *implementation;
	NSMutableDictionary *hierarchy; // should this be per-corpus or global?
	NSString *displayName;
    NSArray *articleURLs;
}

@property (readonly) NSString *displayName;
@property (readonly) NSDictionary *hierarchy;

-(id)initWithImplementationCode:(NSString*)pythonCode;
-(void)setImplementationCode:(NSString*)pythonCode;

-(NSArray*)articleURLs;
-(LTWArticle*)loadArticleWithURL:(NSURL*)url;

@end
