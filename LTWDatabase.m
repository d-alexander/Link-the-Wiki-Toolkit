//
//  LTWDatabase.m
//  LTWToolkit
//
//  Created by David Alexander on 3/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWDatabase.h"


@implementation LTWDatabase

#pragma mark LTWTokens*

// Creates a *new* LTWTokens in the database, and returns the primary key that has been assigned to it.
-(NSUInteger)insertTokensWithText:(NSString*)text {
    return 0;
}

-(void)loadTokensWithText:(NSString**)text numTokens:(NSUInteger*)numTokens numTags:(NSUInteger*)numTags tokensID:(NSUInteger)tokensID {
    
}

#pragma mark NSRange

-(void)insertTokenWithRange:(NSRange)tokenCharRange index:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID {
    
}


-(void)loadTokenWithRange:(NSRange*)tokenCharRange index:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID {
    
}

#pragma mark LTWTokenTag*

-(void)insertTag:(LTWTokenTag*)tag fromTokenIndex:(NSUInteger)firstTokenIndex toTokenIndex:(NSUInteger)lastTokenIndex tokensID:(NSUInteger)tokensID {
    
}

-(void)loadTag:(LTWTokenTag**)tag fromTokenIndex:(NSUInteger*)firstTokenIndex toTokenIndex:(NSUInteger*)lastTokenIndex tagIndex:(NSUInteger)tagIndex tokensID:(NSUInteger)tokensID {
    
}

#pragma mark NSMutableDictionary* (for extraInfo)

// NOTE: This could *ALL* be done with tags instead!
// (Although maybe it wouldn't be ideal for things that could easily be recovered by the parser, like isXML and tagRemainderLength.)

-(void)insertExtraInfo:(NSDictionary*)extraInfo forTokenIndex:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID {
    
}

-(void)loadExtraInfo:(NSDictionary**)extraInfo forTokenIndex:(NSUInteger)tokenIndex tokensID:(NSUInteger)tokensID {
    
}

@end
