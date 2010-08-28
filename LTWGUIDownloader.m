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

// TEMP
static LTWGUIDownloader *instance = nil;

-(id)initWithDelegate:(id)theDelegate {
    if ((self = [super init])) {
        delegate = theDelegate;
        [NSThread detachNewThreadSelector:@selector(downloadAssessments) toTarget:self withObject:nil];
        downloadInProgress = NO;
        instance = [self retain];
    }
    
    return self;
}

static NSString *runLoopMode = @"NSURLConnectionRequestMode";

-(void)spinRunLoopUntilDownloadFinishes {
    while (downloadInProgress) {
        [[NSRunLoop currentRunLoop] runMode:runLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)downloadAssessments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // TODO: Display messages in status bar.
    
    
    do {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://linkthewiki.nfshost.com/getfile.php?last_file_timestamp=0"]];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        downloadFilename = nil;
        downloadFile = NULL;
        downloadInProgress = YES;
        
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];

        [self spinRunLoopUntilDownloadFinishes];
        
        [connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];
        [connection cancel];
        [connection release];
        
        // TODO: Rather than stopping here, update the timestamp and try again. (Unless the current download 404ed.)
    } while (NO);
    
    [pool drain];

}

-(void)handleDownloadedFile:(NSString*)filename {
    LTWDatabase *database = [[LTWDatabase alloc] initWithDataFile:filename];
    [database loadArticlesWithDelegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!downloadFile) {
        downloadFilename = [@""DATA_PATH stringByAppendingPathComponent:@"downloaded_assessments.ltw"];
        downloadFile = fopen([downloadFilename UTF8String], "wb");
    }
    if (downloadFile) fwrite([data bytes], 1, [data length], downloadFile);
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    downloadFilename = [@""DATA_PATH stringByAppendingPathComponent:[response suggestedFilename]];
    downloadFile = fopen([downloadFilename UTF8String], "wb");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (downloadFile) {
        fclose(downloadFile);
        downloadFile = NULL;
        [self handleDownloadedFile:downloadFilename];
    }
    downloadFilename = nil;
    downloadInProgress=NO;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    downloadInProgress=NO;
}


-(void)articleLoaded:(LTWArticle*)article {
    LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(articleLoaded:) argument:article];
    [delegate callOnMainThread:call];
}

@end
