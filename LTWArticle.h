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

@interface LTWArticle : NSObject {
	LTWTokens *tokens;
	LTWCorpus *corpus;
}

-(id)initWithTokens:(LTWTokens*)theTokens corpus:(LTWCorpus*)theCorpus;
-(LTWTokens*)tokens;

@end
