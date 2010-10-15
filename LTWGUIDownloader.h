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
    NSMutableDictionary *databases;
    NSString *proxyHostname;
    NSUInteger proxyPort;
    NSString *proxyUsername;
    NSString *proxyPassword;
    NSString *dataPath;
    NSUInteger numFilesDownloaded;
}

-(id)initWithDelegate:(id)theDelegate proxyHostname:(NSString*)proxyHostname proxyPort:(NSUInteger)proxyPort proxyUsername:(NSString*)theProxyUsername proxyPassword:(NSString*)theProxyPassword dataPath:(NSString*)theDataPath;
-(void)downloadAssessments;
-(void)articleLoaded:(LTWArticle*)article articleID:(NSUInteger)articleID;
-(void)handleFile:(NSString*)filename downloaded:(BOOL)downloaded;
-(void)loadExistingFiles;
-(BOOL)downloadFile;
-(BOOL)uploadFile:(NSString*)filename;
-(void)submitBugReport:(NSString*)text;
-(void)loadFile:(NSString*)filename;
-(void)startLoadAssessmentFile:(NSString*)filename;
-(void)startUploadAssessmentFile:(NSString*)filename;
-(void)startSubmitBugReport:(NSString*)text;

@end
