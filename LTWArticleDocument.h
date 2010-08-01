//
//  LTWArticleDocument.h
//  LTWToolkit
//
//  Created by David Alexander on 1/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWArticle.h"
#import "LTWTokensView.h"

@interface LTWArticleDocument : NSDocument {
	LTWArticle *article;
	IBOutlet LTWTokensView *tokensView;
}

-(void)setArticle:(LTWArticle*)theArticle;

@end
