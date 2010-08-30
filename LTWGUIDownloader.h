//
//  LTWGUIDownloader.h
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWArticle.h"

@interface LTWGUIDownloader : NSObject {
    id delegate;
    NSUInteger lastFileTimestamp;
    BOOL finishedDownloadingFiles;
    BOOL downloadInProgress;
    NSString *downloadFilename;
    FILE *downloadFile;
}

-(id)initWithDelegate:(id)theDelegate;
-(void)downloadAssessments;
-(void)articleLoaded:(LTWArticle*)article;
-(void)handleDownloadedFile:(NSString*)filename;

@end
