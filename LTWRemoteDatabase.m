//
//  LTWRemoteDatabase.m
//  LTWToolkit
//
//  Created by David Alexander on 16/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWRemoteDatabase.h"
#import "LTWDatabase.h"

#import "LTWCocoaPlatform.h"

@implementation LTWRemoteDatabase

#define DB_USERNAME "username"
#define DB_PASSWORD "password"
#define DB_SERVER "192.168.0.105:1433"

int err_handler(DBPROCESS * dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {
    if (dberr) {
		fprintf(stderr, "%s: Msg %d, Level %d\n", 
				"LTW", dberr, severity);
		fprintf(stderr, "%s\n\n", dberrstr);
	}
    
	else {
		fprintf(stderr, "%s: DB-LIBRARY error:\n\t", "LTW");
		fprintf(stderr, "%s\n", dberrstr);
	}
    
	return INT_CANCEL;
}

-(void)downloadNewAssessmentFiles {
#ifndef GTK_PLATFORM
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(setStatus:) withObject:@"Loading assessment file..." waitUntilDone:NO];
#endif
    
    // This is the file I'm using to test the assessment tool until LTWRemoteDatabase can actually load files from a remote server.
    LTWDatabase *testDB = [[LTWDatabase alloc] initWithDataFile:(@"" DATA_PATH @"tokens.db")];
    NSLog(@"Calling loadArticles.");
    //[testDB loadArticles];
    NSLog(@"loadArticles finished.");
    
#ifndef GTK_PLATFORM
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(clearStatus) withObject:nil waitUntilDone:NO];
#endif
}

-(void)startDownloadThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self downloadNewAssessmentFiles];
    
    [pool drain];
}

/*
-(void)downloadNewAssessmentFiles {
#ifndef GTK_PLATFORM
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(setStatus:) withObject:@"Connecting to assessment-file database..." waitUntilDone:NO];
#else
    NSLog(@"Connecting to database...");
#endif
    
    dbinit();
    dberrhandle(err_handler);
    
    LOGINREC *login = dblogin();
    DBSETLUSER(login, DB_USERNAME);
    DBSETLPWD(login, DB_PASSWORD);
    
    DBPROCESS *process = dbopen(login, DB_SERVER);
    //dbuse(process, "ltw");
    
#ifndef GTK_PLATFORM
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(setStatus:) withObject:@"Checking for new assessment files..." waitUntilDone:NO];
#endif
    
    dbfcmd(process, "SELECT data FROM ltw.dbo.UnassessedFiles4;");
    dbsqlexec(process);
    
    while (dbresults(process) != NO_MORE_RESULTS) {
        
        while (true) {
            static char filename[1024];
            static int file_number = 0;
            // NOTE: This WILL currently overwrite existing files!
            snprintf(filename, sizeof filename, "%sassessment_file_%d.db", DATA_PATH, file_number++);
            
            static BYTE data[1024];
            int bytes_read;
            
            FILE *file = fopen(filename, "wb");
            
            NSUInteger total_bytes_read = 0;
            while (0 < (bytes_read = dbreadtext(process, data, sizeof data))) {
                total_bytes_read += bytes_read;
                fwrite(data, sizeof *data, bytes_read, file);
            }
            
            if (bytes_read == 0) {
                fclose(file);
                
                // NOTE: It would be more efficient if we didn't wait for the data file to be loaded before downloading the next one.
                LTWDatabase *db = [[LTWDatabase alloc] initWithDataFile:[NSString stringWithUTF8String:filename]];
                [db loadArticles];
                
                continue;
            }else{
                fclose(file);
                unlink(filename);
                break;
            }
            
        }
        
        break; // TEMP until I can figure out why dbresults doesn't return NO_MORE_RESULTS.
        
    }

#ifndef GTK_PLATFORM
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(clearStatus) withObject:nil waitUntilDone:NO];
#endif
}
*/
 
@end
