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

-(id)initWithBodyTokens:(LTWTokens*)theTokens corpus:(LTWCorpus*)theCorpus URL:(NSString*)theURL; {
	if (self = [super init]) {
        fields = [[NSMutableDictionary alloc] init];
        [fields setObject:theTokens forKey:@"body"];
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
