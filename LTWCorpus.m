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
	NSDictionary *articleInfo = [LTWPythonUtils callMethod:"load_article" onPythonObject:self->implementation withTokens:articleTokens];
	LTWArticle *article = [[[LTWArticle alloc] initWithTokens:articleTokens corpus:self] autorelease];
	
	// NOTE: Currently this doesn't allow articles and hierarchy-nodes to have identical names if they're siblings.
	// NOTE: So that we can look objects up by their indices (required for NSOutlineViewDataSource), we store each item's index as a separate NSNumber key. This means that if we want the *real* number of items we need to divide the count by 2. This is a horrible hack and it should be fixed as soon as possible!
	NSMutableDictionary *curLevel = self->hierarchy;
	for (NSString *component in [articleInfo objectForKey:@"pathInHierarchy"]) {
		NSMutableDictionary *nextLevel = [curLevel objectForKey:component];
		if (!nextLevel) {
			NSUInteger count = [curLevel count] / 2;
			nextLevel = [[NSMutableDictionary alloc] init];
			[curLevel setObject:nextLevel forKey:component];
			[curLevel setObject:nextLevel forKey:[NSNumber numberWithInt:count]];
		}
		
		curLevel = nextLevel;
		[nextLevel release];
	}
	NSUInteger count = [curLevel count] / 2;
	[curLevel setObject:article forKey:[articleInfo objectForKey:@"articleTitle"]];
	[curLevel setObject:article forKey:[NSNumber numberWithInt:count]];
	
	// Temporary code for testing the LTWTokensView with some tags.
	NSRange bodyTokens = [[articleInfo objectForKey:@"bodyTokens"] rangeValue];
	[[articleTokens tokensFromIndex:bodyTokens.location toIndex:NSMaxRange(bodyTokens)-1 propagateTags:YES] addTag:[[LTWTokenTag alloc] initWithName:@"This is a test" value:@"ASDF"]];
	LTWArticleDocument *doc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"nz.ac.otago.inex.ltw-toolkit.article"];
	[doc setArticle:article];
	
	return article;
}

@end
