//
//  LTWRemoteDatabase.m
//  LTWToolkit
//
//  Created by David Alexander on 16/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWRemoteDatabase.h"

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
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(setStatus:) withObject:@"Connecting to assessment-file database..." waitUntilDone:NO];
    
    dbinit();
    dberrhandle(err_handler);
    
    LOGINREC *login = dblogin();
    DBSETLUSER(login, DB_USERNAME);
    DBSETLPWD(login, DB_PASSWORD);
    
    DBPROCESS *process = dbopen(login, DB_SERVER);
    //dbuse(process, "ltw");
    
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(setStatus:) withObject:@"Checking for new assessment files..." waitUntilDone:NO];
    
    dbfcmd(process, "SELECT name, data FROM ltw.dbo.UnassessedFiles3;");
    dbsqlexec(process);
    
    while (dbresults(process) != NO_MORE_RESULTS) {
        
        while (dbnextrow(process) != NO_MORE_ROWS) {
            static char filename[1024];
            BYTE *data;
            NSUInteger length;
            
            data = dbdata(process, 1);
            length = dbdatlen(process, 1);
            if (length > sizeof filename - 1) length = sizeof filename - 1;
            strncpy(filename, (char*)data, length);
            
            FILE *file = fopen(filename, "wb");
            data = dbdata(process, 2);
            length = dbdatlen(process, 2);
            fwrite(data, sizeof *data, length, file);
            fclose(file);
        }
        
    }
    
    [[LTWCocoaPlatform sharedInstance] performSelectorOnMainThread:@selector(clearStatus) withObject:nil waitUntilDone:NO];
}

@end
