//
//  LTWTokensView.h
//  LTWToolkit
//
//  Created by David Alexander on 1/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWTokens.h"

@interface LTWTokensView : NSTextView {
	LTWTokens *tokens;
}

-(void)setTokens:(LTWTokens*)theTokens;

@end
