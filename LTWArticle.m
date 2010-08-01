//
//  LTWArticle.m
//  LTWToolkit
//
//  Created by David Alexander on 28/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWArticle.h"


@implementation LTWArticle

-(id)initWithTokens:(LTWTokens*)theTokens corpus:(LTWCorpus*)theCorpus {
	if (self = [super init]) {
		self->tokens = [theTokens retain];
		self->corpus = [theCorpus retain];
	}
	return self;
}

-(LTWTokens*)tokens {
	return tokens;
}

@end
