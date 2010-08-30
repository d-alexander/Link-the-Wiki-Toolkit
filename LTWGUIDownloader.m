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
        lastFileTimestamp = 0;
        finishedDownloadingFiles = NO;
        downloadInProgress = NO;
        instance = [self retain];
        
        // To prevent a race condition, this must be done AFTER all the ivars have been filled in.
        [NSThread detachNewThreadSelector:@selector(downloadAssessments) toTarget:self withObject:nil];
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
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:(@""DATA_PATH)];
    for (NSString *filename = [enumerator nextObject]; filename; filename = [enumerator nextObject]) {
        if ([filename hasSuffix:@".ltw"]) {
            [self handleDownloadedFile:[@""DATA_PATH stringByAppendingPathComponent:filename]];
        }
    }
    
    
    finishedDownloadingFiles = NO;
    
    while (!finishedDownloadingFiles) {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://linkthewiki.nfshost.com/getfile.php?last_file_timestamp=%d", lastFileTimestamp]]];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        downloadFilename = nil;
        downloadFile = NULL;
        downloadInProgress = YES;
        
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];

        [self spinRunLoopUntilDownloadFinishes];
        
        [connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];
        [connection cancel];
        [connection release];
        [request release];
    }
    
    NSLog(@"Finished downloading assessment files.");
    
    [pool drain];

}

-(void)handleDownloadedFile:(NSString*)filename {
    LTWDatabase *database = [[LTWDatabase alloc] initWithDataFile:filename];
    lastFileTimestamp = [database assessmentFileTimestamp];
    [database loadArticlesWithDelegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!downloadFile) {
        // Temporary hack to see if we've got a 404.
        if ([data length] > 6 && memcmp([data bytes], "SQLite", 6) != 0) {
            downloadInProgress = NO;
            finishedDownloadingFiles = YES;
            return;
        }
        
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
    downloadInProgress = NO;
    finishedDownloadingFiles = YES;
}


-(void)articleLoaded:(LTWArticle*)article {
    LTWGUIMethodCall *call = [[LTWGUIMethodCall alloc] initWithSelector:@selector(articleLoaded:) argument:article];
    [delegate callOnMainThread:call];
}

@end
