//
//  LTWArticle.h
//  LTWToolkit
//
//  Created by David Alexander on 28/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWTokens.h"

@class LTWCorpus;
@class LTWTokens;

@interface LTWArticle : NSObject {
	NSMutableDictionary *fields;
	LTWCorpus *corpus;
    NSString *URL;
}

-(id)initWithCorpus:(LTWCorpus*)theCorpus URL:(NSString*)theURL;
-(NSArray*)fieldNames;
-(LTWTokens*)tokensForField:(NSString*)fieldName;
-(void)addTokens:(LTWTokens*)theTokens forField:(NSString*)fieldName;
-(void)pageOut;

@property (readonly) LTWCorpus *corpus;
@property (readonly) NSString *URL;

@end
