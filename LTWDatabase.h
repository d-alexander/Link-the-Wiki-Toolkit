//
//  LTWDatabase.h
//  LTWToolkit
//
//  Created by David Alexander on 3/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "LTWTokenTag.h"
#import "LTWArticle.h"

@class LTWArticle;
@interface LTWDatabase : NSObject {
    sqlite3 *database;
}

-(void)beginTransaction;
-(void)commit;

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

-(NSDictionary*)loadArticles;

@end
