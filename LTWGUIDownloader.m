//
//  LTWGUIDownloader.m
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIDownloader.h"

#import "LTWGUIMediator.h"
#import "LTWDatabase.h"

@implementation LTWGUIDownloader

-(id)initWithDelegate:(id)theDelegate {
    if ((self = [super init])) {
        delegate = theDelegate;
        [NSThread detachNewThreadSelector:@selector(downloadAssessments) toTarget:self withObject:nil];
    }
    
    return self;
}

-(void)downloadAssessments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // TODO: Display messages in status bar.
    
    // This is the file I'm using to test the assessment tool until we can actually load files from a remote server.
    LTWDatabase *testDB = [[LTWDatabase alloc] initWithDataFile:(@"" DATA_PATH @"tokens.db")];
    
    [testDB loadArticlesWithDelegate:self];
    
    [pool drain];

}

-(void)articleLoaded:(LTWArticle*)article {
    LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(articleLoaded:) argument:article];
    [delegate callOnMainThread:call];
}

@end
