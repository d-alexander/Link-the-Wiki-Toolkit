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
#import "LTWTokenProcessor.h"
#import "LTWSearch.h"
#import "LTWDatabase.h"

@implementation LTWToolkitAppDelegate

@synthesize window;
@synthesize corpora;
@synthesize tokenProcessors;
@synthesize articleURLField;

-(id)init {
	if (self = [super init]) {
		self->corpora = [[NSMutableArray alloc] init];
        self->tokenProcessors = [[NSMutableArray alloc] init];
        self->articles = [[NSMutableArray alloc] init];
	}
	return self;
}

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
	if ([corpora count] > 0) {
		LTWCorpus *corpus = [corpora lastObject];
		NSURL *url = [NSURL URLWithString:[articleURLField stringValue]];
		if (!url) return;
		LTWArticle *article = [corpus loadArticleWithURL:url];
		[articleSelectionView reloadItem:nil reloadChildren:YES];
        [articles addObject:article];
	}
}

// Processes all of the currently-loaded articles using all of the currently-loaded token processors.
// NOTE: This is for testing; article re-processing will hopefully be co-ordinated in a much better way later.
-(IBAction)processArticles:(id)sender {
    NSMutableArray *searches = [NSMutableArray array];
    
    for (LTWTokenProcessor *tokenProcessor in tokenProcessors) {
        [searches addObjectsFromArray:[tokenProcessor initialSearches]];
    }
    
    NSMutableDictionary *loadedArticles = [NSMutableDictionary dictionary];
    
    BOOL keepGoing;
    BOOL firstPass = YES;
    NSUInteger articlesProcessed = 0;
    do {
        keepGoing = NO;
        
        for (LTWCorpus *corpus in corpora) {
        
            NSArray *urls = [corpus articleURLs];
            
            for (NSString *url in urls) {
                LTWArticle *article;
                // Get the next article, by loading from URL or database.
                if (firstPass) {
                    article = [corpus loadArticleWithURL:[NSURL URLWithString:url]];
                    [loadedArticles setObject:article forKey:url];
                }else{
                    article = [loadedArticles objectForKey:url];
                }
                
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
                for (NSString *fieldName in [article fieldNames]) {
                    LTWTokens *fieldTokens = [article tokensForField:fieldName];
                    
                    NSUInteger tokenIndex = 0;
                    for (NSValue *tokenRangeValue in fieldTokens) {
                        NSMutableArray *newSearches = [[NSMutableArray alloc] init];
                        for (LTWSearch *search in searches) {
                            if ([search tryOnTokenIndex:tokenIndex ofTokens:fieldTokens fieldName:fieldName corpusName:[[article corpus] displayName] articleURL:[article URL] newSearches:newSearches]) keepGoing = YES;
                        }
                        
                        // TEMP
                        if ([newSearches count] > 0) {
                            NSLog(@"New searches: %@", newSearches);
                        }
                        
                        [searches addObjectsFromArray:newSearches];
                        [newSearches release];
                        
                        tokenIndex++;
                    }
                    
                    if ([loadedArticles count] > 0) {
                        NSUInteger tokenIndex = rand()%10;
                        while (tokenIndex < [fieldTokens count]) {
                            NSUInteger linkEnd = tokenIndex + rand()%5;
                            if (linkEnd >= [fieldTokens count]) break;
                            
                            LTWArticle *linkTarget = [[loadedArticles allKeys] objectAtIndex:rand()%[loadedArticles count]];
                            
                            [fieldTokens _addTag:[[[LTWTokenTag alloc] initWithName:@"linked_to" value:linkTarget] autorelease] fromIndex:tokenIndex toIndex:linkEnd];
                            
                            tokenIndex = linkEnd + rand()%10;
                        }
                    }
                    
                    [fieldTokens saveToDatabase];
                }
                
                
                [pool drain];
                
                articlesProcessed++;
                if (articlesProcessed > 500) break;
            }
        }
        
        firstPass = NO;
    } while (keepGoing);
    
    [[LTWDatabase sharedInstance] beginTransaction];
    
    for (LTWArticle *articleURL in loadedArticles) {
        [[LTWDatabase sharedInstance] insertArticle:[loadedArticles objectForKey:articleURL]];
    }
    
    [[LTWDatabase sharedInstance] commit];
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
