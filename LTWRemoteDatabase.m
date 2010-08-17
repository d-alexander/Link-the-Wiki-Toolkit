//
//  LTWRemoteDatabase.m
//  LTWToolkit
//
//  Created by David Alexander on 16/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWRemoteDatabase.h"


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

+(void)initialize {
    dbinit();
    
    dberrhandle(err_handler);
    
    LOGINREC *login = dblogin();
    DBSETLUSER(login, DB_USERNAME);
    DBSETLPWD(login, DB_PASSWORD);
    
    DBPROCESS *process = dbopen(login, DB_SERVER);
    //dbuse(process, "ltw");
    dbfcmd(process, "SELECT * FROM ltw.dbo.UnassessedFiles3");
    dbsqlexec(process);
    
    while (dbresults(process) != NO_MORE_RESULTS) {

        
		struct COL
		{ 
			char *name; 
			char *buffer; 
			int type, size, status; 
		} *columns, *pcol;
		int ncols;
		int row_code;
		
		
		ncols = dbnumcols(process);
        
		if ((columns = calloc(ncols, sizeof(struct COL))) == NULL) {
			perror(NULL);
			exit(1);
		}
        
		/* 
		 * Read metadata and bind.  
		 */
		for (pcol = columns; pcol - columns < ncols; pcol++) {
			int c = pcol - columns + 1;
			
			pcol->name = dbcolname(process, c);
			pcol->type = dbcoltype(process, c);
			pcol->size = dbcollen(process, c);
			
			if (SYBCHAR != pcol->type) {
				pcol->size = dbwillconvert(pcol->type, SYBCHAR);
			}
            
			printf("%*s ", pcol->size, pcol->name);
            
			if ((pcol->buffer = calloc(1, pcol->size + 1)) == NULL){
				perror(NULL);
				exit(1);
			}
            
            dbbind(process, c, NTBSTRINGBIND,	
					     pcol->size+1, (BYTE*)pcol->buffer);
                
			dbnullbind(process, c, &pcol->status);	
			
		}
		printf("\n");
		
		/* 
		 * Print the data to stdout.  
		 */
		while ((row_code = dbnextrow(process)) != NO_MORE_ROWS){	
			switch (row_code) {
                case REG_ROW:
                    for (pcol=columns; pcol - columns < ncols; pcol++) {
                        char *buffer = pcol->status == -1? 
						"NULL" : pcol->buffer;
                        printf("%*s ", pcol->size, buffer);
                    }
                    printf("\n");
                    break;
                    
                case BUF_FULL:
                    assert(row_code != BUF_FULL);
                    break;
                    
                case FAIL:
                    fprintf(stderr, "%s:%d: dbresults failed\n", 
                            "LTW", __LINE__);
                    exit(1);
                    break;
                    
                default: 					
                    printf("Data for computeid %d ignored\n", row_code);
			}
            
            
		}
        
		/* free metadata and data buffers */
		for (pcol=columns; pcol - columns < ncols; pcol++) {
			free(pcol->buffer);
		}
		free(columns);
        
		/* 
		 * Get row count, if available.   
		 */
		if (DBCOUNT(process) > -1)
			fprintf(stderr, "%d rows affected\n", DBCOUNT(process));
        
		/* 
		 * Check return status 
		 */
		if (dbhasretstat(process) == TRUE) {
			printf("Procedure returned %d\n", dbretstatus(process));
		}

        
        
    }
}

@end
