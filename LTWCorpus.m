//
//  LTWCorpus.m
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWCorpus.h"

#import "LTWTokens.h"

#import "LTWArticleDocument.h" //temp

@implementation LTWCorpus

@synthesize hierarchy;
@synthesize displayName;

-(id)initWithImplementationCode:(NSString*)pythonCode {
	if (self = [super init]) {
		if (pythonCode) {
			self->implementation = [LTWPythonUtils compilePythonObjectFromCode:pythonCode];
			self->hierarchy = [[NSMutableDictionary alloc] init];
			self->displayName = @"(corpus)";
		}
	}
	return self;
}

-(void)setImplementationCode:(NSString*)pythonCode {
	Py_XDECREF(self->implementation);
	self->implementation = [LTWPythonUtils compilePythonObjectFromCode:pythonCode];
}

-(LTWArticle*)loadArticleWithURL:(NSURL*)url {
	NSString *xml = [NSString stringWithContentsOfURL:url];
	LTWTokens *articleTokens = [[LTWTokens alloc] initWithXML:xml];
    
    NSArray *pathInHierarchy = nil;
    NSDictionary *articleFields = nil;
    
	[LTWPythonUtils callMethod:"load_article" onPythonObject:self->implementation withArgument:(PyObject*)[LTWPythonUtils pythonIteratorForTokens:articleTokens] depythonise:YES returnFormat:"OO", &pathInHierarchy, &articleFields, NULL];
    
    LTWTokens *bodyTokens = [articleFields objectForKey:@"body"];
    if (!bodyTokens) return nil;
    
	LTWArticle *article = [[[LTWArticle alloc] initWithBodyTokens:bodyTokens corpus:self URL:[url absoluteString]] autorelease];
	for (NSString *fieldName in bodyTokens) {
        if ([fieldName isEqual:@"body"]) continue;
        [article addTokens:[articleFields objectForKey:fieldName] forField:fieldName];
    }
    
    NSString *articleTitle = ([articleFields objectForKey:@"title"] != nil) ? [(LTWTokens*)[articleFields objectForKey:@"title"] stringValue] : @"(no title)";
    
	// NOTE: Currently this doesn't allow articles and hierarchy-nodes to have identical names if they're siblings.
	// NOTE: So that we can look objects up by their indices (required for NSOutlineViewDataSource), we store each item's index as a separate NSNumber key. This means that if we want the *real* number of items we need to divide the count by 2. This is a horrible hack and it should be fixed as soon as possible!
	NSMutableDictionary *curLevel = self->hierarchy;
	for (NSString *component in pathInHierarchy) {
		NSMutableDictionary *nextLevel = [curLevel objectForKey:component];
		if (!nextLevel) {
			NSUInteger count = [curLevel count] / 2;
			nextLevel = [[NSMutableDictionary alloc] init];
			[curLevel setObject:nextLevel forKey:component];
			[curLevel setObject:nextLevel forKey:[NSNumber numberWithInt:count]];
            curLevel = nextLevel;
            [nextLevel release];
		}else{
            curLevel = nextLevel;
        }
		
	}
	NSUInteger count = [curLevel count] / 2;
	[curLevel setObject:article forKey:articleTitle];
	[curLevel setObject:article forKey:[NSNumber numberWithInt:count]];
    
	LTWArticleDocument *doc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"nz.ac.otago.inex.ltw-toolkit.article" error:NULL];
    [[NSDocumentController sharedDocumentController] addDocument:doc];
	[doc setArticle:article];
    [doc makeWindowControllers];
    [doc showWindows];
	
	return article;
}

@end
