//
//  LTWDatabase.h
//  LTWToolkit
//
//  Created by David Alexander on 3/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LTWTokenTag.h"


@interface LTWDatabase : NSObject {

}

-(NSUInteger)insertTokensWithText:(NSString*)text;

-(void)loadTokensWithText:(NSString**)text numTokens:(NSUInteger*)numTokens numTags:(NSUInteger*)numTags tokensID:(NSUInteger)tokensID;

#pragma mark NSRange

-(void)insertTokenWithRange:(NSRange)tokenCharRange index:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID;


-(void)loadTokenWithRange:(NSRange*)tokenCharRange index:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID;

#pragma mark LTWTokenTag*

-(void)insertTag:(LTWTokenTag*)tag fromTokenIndex:(NSUInteger)firstTokenIndex toTokenIndex:(NSUInteger)lastTokenIndex tokensID:(NSUInteger)tokensID;

-(void)loadTag:(LTWTokenTag**)tag fromTokenIndex:(NSUInteger*)firstTokenIndex toTokenIndex:(NSUInteger*)lastTokenIndex tagIndex:(NSUInteger)tagIndex tokensID:(NSUInteger)tokensID;

#pragma mark NSDictionary* (for extraInfo)

-(void)insertExtraInfo:(NSDictionary*)extraInfo forTokenIndex:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID;

-(void)loadExtraInfo:(NSDictionary**)extraInfo forTokenIndex:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID;

@end
