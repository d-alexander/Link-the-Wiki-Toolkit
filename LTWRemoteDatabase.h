//
//  LTWRemoteDatabase.h
//  LTWToolkit
//
//  Created by David Alexander on 16/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Stop sybdb.h from redefining BOOL. We do this by pretending to be some other system that already has STATUS and BOOL defined (therefore, WE have to define STATUS!)
#define __INCvxWorksh
typedef int STATUS;

#import <sqlfront.h>
#import <sqldb.h>
//#import <tds.h>

@interface LTWRemoteDatabase : NSObject {
    
}

-(void)downloadNewAssessmentFiles;
-(void)startDownloadThread;

@end
