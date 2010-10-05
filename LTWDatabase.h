//
//  LTWDatabase.h
//  LTWToolkit
//
//  Created by David Alexander on 3/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "sqlite3async.h"

#import "LTWTokenTag.h"
#import "LTWArticle.h"

// NOTE: We're relying on each of the pointers in this struct being zeroed automatically.
typedef struct {
    sqlite3_stmt *beginTransaction;
    sqlite3_stmt *commit;
    sqlite3_stmt *insertTokens;
    sqlite3_stmt *loadTokens;
    sqlite3_stmt *insertRange;
    sqlite3_stmt *loadRanges;
    sqlite3_stmt *insertTag;
    sqlite3_stmt *loadTag;
    sqlite3_stmt *insertArticle;
    sqlite3_stmt *insertField;
    sqlite3_stmt *loadArticles;
    sqlite3_stmt *getAssessmentFileTimestamp;
} LTWDatabaseStatements;

@class LTWArticle;
@interface LTWDatabase : NSObject {
    sqlite3 *database;
    LTWDatabaseStatements statements;
    NSUInteger numNestedTransactions;
}

-(sqlite3*)databaseConnection;
-(sqlite3_stmt*)initialiseStatement:(sqlite3_stmt**)statement withQuery:(const char *)query;

-(id)initWithDataFile:(NSString*)dataFilename;
+(void)stopAsynchronousThread;

-(void)beginTransaction;
-(void)commit;

+(void)setSharedDatabaseFile:(NSString*)filePath;
+(LTWDatabase*)sharedInstance;

-(NSUInteger)insertTokensWithText:(NSString*)text;

-(void)loadTokensWithText:(NSString**)text numTokens:(NSUInteger*)numTokens numTags:(NSUInteger*)numTags tokensID:(NSUInteger)tokensID;

#pragma mark NSRange

-(void)insertTokenWithRange:(NSRange)tokenCharRange index:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID;


-(void)loadTokenWithRanges:(NSArray**)tokenCharRanges tokensID:(NSUInteger)tokensID;

#pragma mark LTWTokenTag*

-(void)insertTag:(LTWTokenTag*)tag withIndex:(NSUInteger)tagIndex fromTokenIndex:(NSUInteger)firstTokenIndex toTokenIndex:(NSUInteger)lastTokenIndex tokensID:(NSUInteger)tokensID;

-(void)loadTag:(LTWTokenTag**)tag fromTokenIndex:(NSUInteger*)firstTokenIndex toTokenIndex:(NSUInteger*)lastTokenIndex tagIndex:(NSUInteger)tagIndex tokensID:(NSUInteger)tokensID;

#pragma mark LTWArticle*

-(NSUInteger)insertArticle:(LTWArticle*)article;

-(void)loadArticlesWithDelegate:(id)delegate;

#pragma mark LTWAssessmentFile

-(NSUInteger)assessmentFileTimestamp;

@end
