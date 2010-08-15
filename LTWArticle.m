//
//  LTWArticle.m
//  LTWToolkit
//
//  Created by David Alexander on 28/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWArticle.h"


@implementation LTWArticle

@synthesize corpus;
@synthesize URL;

-(id)initWithCorpus:(LTWCorpus*)theCorpus URL:(NSString*)theURL {
	if (self = [super init]) {
        fields = [[NSMutableDictionary alloc] init];
        
        // NOTE: Currently, corpus and URL aren't set properly when an article is loaded from the database!
		corpus = [theCorpus retain];
        URL = [theURL retain];
	}
	return self;
}

-(NSArray*)fieldNames {
    return [fields allKeys];
}

-(LTWTokens*)tokensForField:(NSString*)fieldName {
	return [fields objectForKey:fieldName];
}

-(void)addTokens:(LTWTokens*)theTokens forField:(NSString*)fieldName {
    [fields setObject:theTokens forKey:fieldName];
}

-(void)pageOut {
    for (NSString *fieldName in fields) {
        [[fields objectForKey:fieldName] saveToDatabase];
    }
}

@end
