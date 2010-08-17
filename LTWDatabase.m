//
//  LTWDatabase.m
//  LTWToolkit
//
//  Created by David Alexander on 3/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWDatabase.h"


@implementation LTWDatabase

-(id)init {
    if (self = [super init]) {
        sqlite3_open(DATA_PATH "/tokens.db", &database);
        
    }
    return self;
}

+(LTWDatabase*)sharedInstance {
    static LTWDatabase *instance = nil;
    if (!instance) instance = [[LTWDatabase alloc] init];
    return instance;
}

// TODO: Write a varargs method that can initialise, bind and run arbitrary queries.
-(void)initialiseStatement:(sqlite3_stmt**)statement withQuery:(const char *)query {
    // If the statement hasn't already been prepared, prepare it. Otherwise, reset the state and bindings.
    if (!*statement) {
        sqlite3_prepare(database, query, -1, statement, NULL);
    }else{
        sqlite3_reset(*statement);
        sqlite3_clear_bindings(*statement);
    }
}

-(void)beginTransaction {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"BEGIN TRANSACTION;"];
    sqlite3_step(statement);
}

-(void)commit {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"COMMIT;"];
    sqlite3_step(statement);
}

#pragma mark LTWTokens*

// Creates a *new* LTWTokens in the database, and returns the primary key that has been assigned to it.
-(NSUInteger)insertTokensWithText:(NSString*)text {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"INSERT INTO LTWTokens VALUES (NULL, ?);"];
    sqlite3_bind_text(statement, 1, [text UTF8String], -1, SQLITE_STATIC);
    sqlite3_step(statement);
    return sqlite3_last_insert_rowid(database);
}

-(void)loadTokensWithText:(NSString**)text numTokens:(NSUInteger*)numTokens numTags:(NSUInteger*)numTags tokensID:(NSUInteger)tokensID {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"SELECT text, (SELECT COUNT(*) FROM LTWTokens_ranges where tokens_id = id) AS num_tokens, (SELECT COUNT(*) FROM LTWTokens_tags where tokens_id = id) AS num_tags FROM LTWTokens WHERE id = ?;"];
    sqlite3_bind_int(statement, 1, tokensID);
    if (sqlite3_step(statement) != SQLITE_ROW) {
        NSLog(@"Couldn't find LTWTokens with ID %u in database.", tokensID);
        return;
    }
    *text = [[NSString stringWithUTF8String:(const char*)sqlite3_column_text(statement, 0)] retain];
    *numTokens = sqlite3_column_int(statement, 1);
    *numTags = sqlite3_column_int(statement, 2);
}

#pragma mark NSRange

-(void)insertTokenWithRange:(NSRange)tokenCharRange index:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"INSERT INTO LTWTokens_ranges VALUES (?, ?, ?, ?);"];
    
    sqlite3_bind_int(statement, 1, tokensID);
    sqlite3_bind_int(statement, 2, tokenIndex);
    sqlite3_bind_int(statement, 3, tokenCharRange.location);
    sqlite3_bind_int(statement, 4, tokenCharRange.length);
    sqlite3_step(statement);
}


-(void)loadTokenWithRanges:(NSArray**)tokenCharRanges tokensID:(NSUInteger)tokensID {
    *tokenCharRanges = [NSMutableArray array];
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"SELECT range_location, range_length FROM LTWTokens_ranges WHERE tokens_id = ?;"];
    sqlite3_bind_int(statement, 1, tokensID);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        NSRange tokenCharRange;
        tokenCharRange.location = sqlite3_column_int(statement, 0);
        tokenCharRange.length = sqlite3_column_int(statement, 1);
        [(NSMutableArray*)*tokenCharRanges addObject:[NSValue valueWithRange:tokenCharRange]];
    }
}

#pragma mark LTWTokenTag*

-(void)insertTag:(LTWTokenTag*)tag withIndex:(NSUInteger)tagIndex fromTokenIndex:(NSUInteger)firstTokenIndex toTokenIndex:(NSUInteger)lastTokenIndex tokensID:(NSUInteger)tokensID {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"INSERT INTO LTWTokens_tags VALUES (?, ?, ?, ?, ?, ?);"];
    sqlite3_bind_int(statement, 1, tokensID);
    sqlite3_bind_int(statement, 2, tagIndex);
    sqlite3_bind_int(statement, 3, firstTokenIndex);
    sqlite3_bind_int(statement, 4, lastTokenIndex);
    sqlite3_bind_text(statement, 5, [[tag tagName] UTF8String], -1, SQLITE_STATIC);
    sqlite3_bind_text(statement, 6, [[[tag tagValue] description] UTF8String], -1, SQLITE_STATIC);
    sqlite3_step(statement);
}

-(void)loadTag:(LTWTokenTag**)tag fromTokenIndex:(NSUInteger*)firstTokenIndex toTokenIndex:(NSUInteger*)lastTokenIndex tagIndex:(NSUInteger)tagIndex tokensID:(NSUInteger)tokensID {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"SELECT first_token_index, last_token_index, tag_name, tag_value FROM LTWTokens_tags WHERE tokens_id = ? AND tag_index = ?;"];
    sqlite3_bind_int(statement, 1, tokensID);
    sqlite3_bind_int(statement, 2, tagIndex);
    sqlite3_step(statement);
    *firstTokenIndex = sqlite3_column_int(statement, 0);
    *lastTokenIndex = sqlite3_column_int(statement, 1);
    *tag = [[LTWTokenTag alloc] initWithName:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(statement, 2)] value:[NSString stringWithUTF8String:(const char*)sqlite3_column_text(statement, 3)]];
}

#pragma mark LTWArticle*

-(NSUInteger)insertArticle:(LTWArticle*)article {
    static sqlite3_stmt *articleInsertStatement = NULL;
    [self initialiseStatement:&articleInsertStatement withQuery:"INSERT INTO LTWArticle VALUES (NULL, ?);"];
    sqlite3_bind_text(articleInsertStatement, 1, [[article URL] UTF8String], -1, SQLITE_STATIC);
    sqlite3_step(articleInsertStatement);
    
    NSUInteger articleID = sqlite3_last_insert_rowid(database);
    
    for (NSString *fieldName in [article fieldNames]) {
        static sqlite3_stmt *fieldInsertStatement = NULL;
        [self initialiseStatement:&fieldInsertStatement withQuery:"INSERT INTO LTWArticle_fields VALUES (?, ?, ?);"];
        
        NSUInteger tokensID = [[article tokensForField:fieldName] databaseID];
        
        sqlite3_bind_int(fieldInsertStatement, 1, articleID);
        sqlite3_bind_text(fieldInsertStatement, 2, [fieldName UTF8String], -1, SQLITE_STATIC);
        sqlite3_bind_int(fieldInsertStatement, 3, tokensID);
        sqlite3_step(fieldInsertStatement);
        
    }
    
    return articleID;
}

-(NSDictionary*)loadArticles {
    static sqlite3_stmt *statement = NULL;
    [self initialiseStatement:&statement withQuery:"SELECT article_id, field_name, tokens_id FROM LTWArticle_fields;"];
    
    NSMutableDictionary *articles = [NSMutableDictionary dictionary];
    
    while (sqlite3_step(statement) == SQLITE_ROW) {
        NSUInteger articleID = sqlite3_column_int(statement, 0);
        NSString *fieldName = [NSString stringWithUTF8String:(char const*)sqlite3_column_text(statement, 1)];
        NSUInteger tokensID = sqlite3_column_int(statement, 2);
        
        LTWArticle *article = [articles objectForKey:[NSNumber numberWithInt:articleID]];
        if (!article) {
            article = [[LTWArticle alloc] initWithCorpus:nil URL:@""];
            [articles setObject:article forKey:[NSNumber numberWithInt:articleID]];
            [article release];
        }
        
        [article addTokens:[[[LTWTokens alloc] initWithDatabase:self tokensID:tokensID] autorelease] forField:fieldName];
    }
    
    return articles;
}


@end
