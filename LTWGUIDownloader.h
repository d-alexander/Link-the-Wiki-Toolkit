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
}

-(id)initWithDelegate:(id)theDelegate;
-(void)downloadAssessments;
-(void)articleLoaded:(LTWArticle*)article articleID:(NSUInteger)articleID;
-(void)handleFile:(NSString*)filename downloaded:(BOOL)downloaded;
-(void)loadExistingFiles;
-(BOOL)downloadFile;
-(BOOL)uploadFile:(NSString*)filename;
-(void)loadFile:(NSString*)filename;
-(void)startLoadAssessmentFile:(NSString*)filename;

@end
