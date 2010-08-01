//
//  LTWToolkitAppDelegate.m
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWToolkitAppDelegate.h"

#import "LTWCorpus.h"
#import "LTWPythonDocument.h"

@implementation LTWToolkitAppDelegate

@synthesize window;
@synthesize corpora;

-(id)init {
	if (self = [super init]) {
		self->corpora = [[NSMutableArray alloc] init];
	}
	return self;
}

// Testing the version editor...

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	NSArray *openPythonFilenames = [[NSUserDefaults standardUserDefaults] objectForKey:@"openPythonFilenames"];
	for (NSString *filename in openPythonFilenames) {
		NSURL *url = [NSURL URLWithString:filename];
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:NULL];
	}
}

-(void)applicationWillTerminate:(NSNotification *)notification {
	[[NSDocumentController sharedDocumentController] saveAllDocuments:self]; // does the document controller already do this for us on termination?
	NSMutableArray *openPythonFilenames = [NSMutableArray array];
	for (NSDocument *document in [[NSDocumentController sharedDocumentController] documents]) {
		if ([document isKindOfClass:[LTWPythonDocument class]]) {
			if ([document fileURL]) {
				[openPythonFilenames addObject:[[document fileURL] absoluteString]];
			}
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:openPythonFilenames forKey:@"openPythonFilenames"];
}


-(IBAction)loadArticle:(id)sender {
	if ([self->corpora count] > 0) {
		LTWCorpus *corpus = [self->corpora lastObject];
		NSURL *url = [NSURL URLWithString:[self->articleURLField stringValue]];
		if (!url) return;
		LTWArticle *article = [corpus loadArticleWithURL:url];
		[self->articleSelectionView reloadItem:nil reloadChildren:YES];
	}
}

- (NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item {
	if (!item) {
		return [self->corpora count];
	}else if ([item isKindOfClass:[NSDictionary class]]) {
		return [(NSDictionary*)item count] / 2;
	}else if ([item isKindOfClass:[LTWCorpus class]]) {
		return [[(LTWCorpus*)item hierarchy] count] / 2;
	}else{
		return 0;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	if (!item || [item isKindOfClass:[LTWCorpus class]] || [item isKindOfClass:[NSDictionary class]]) {
		return YES;
	}else{
		return NO;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if (!item) {
		return [self->corpora objectAtIndex:index];
	}else if ([item isKindOfClass:[NSDictionary class]]) {
		return [(NSDictionary*)item objectForKey:[NSNumber numberWithInt:index]];
	}else if ([item isKindOfClass:[LTWCorpus class]]) {
		return [[(LTWCorpus*)item hierarchy] objectForKey:[NSNumber numberWithInt:index]];
	}else{
		return nil;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	id parent = [outlineView parentForItem:item];
	if (parent && ([parent isKindOfClass:[NSDictionary class]] || [parent isKindOfClass:[LTWCorpus class]])) {
		if ([parent isKindOfClass:[LTWCorpus class]]) parent = [(LTWCorpus*)parent hierarchy];
		for (id key in [(NSDictionary*)parent allKeysForObject:item]) {
			if ([key isKindOfClass:[NSString class]]) return key;
		}
		return nil;
	}else if ([item isKindOfClass:[LTWCorpus class]]) {
		return [(LTWCorpus*)item displayName];
	}else{
		return nil;
	}
}



@end
