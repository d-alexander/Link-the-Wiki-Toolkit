//
//  LTWTokensView.m
//  LTWToolkit
//
//  Created by David Alexander on 1/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWTokensView.h"


@implementation LTWTokensView

-(id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)tokenTagsChanged:(NSNotification*)notification {
	[[self textStorage] setAttributes:[NSDictionary dictionary] range:NSMakeRange(0, [[self textStorage] length])];
	[self setTokens:tokens];
}

-(void)setTokens:(LTWTokens*)theTokens {
    if (theTokens != tokens) {
        [tokens release];
        tokens = [theTokens retain];
    }
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenTagsChanged:) name:LTWTokenTagsChangedNotification object:theTokens];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
    
    /*
     NOTE: Here we're juggling two sets of character-ranges: the ranges in [theTokens _text] and the ranges in the NSAttributedString that we're creating. This is kind of messy at the moment, and should be cleaned up.
     */
    NSUInteger tokenIndex = 0;
    for (NSValue *rangeValue in theTokens) {
        NSUInteger tokenStart = [attributedString length];
        NSRange tokenRange = [rangeValue rangeValue];
        NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:[[theTokens _text] substringWithRange:tokenRange]];
        [attributedString appendAttributedString:tokenString];
        [attributedString appendAttributedString:space];
        [tokenString release];
        
        for (LTWTokenTag *tag in [theTokens tagsStartingAtTokenIndex:tokenIndex]) {
            // NOTE: Should actually be getting the full range of each tag, not just the start token.
            NSRange tagCharRange = NSMakeRange(tokenStart, [attributedString length] - tokenStart);
            
            [attributedString addAttribute:NSToolTipAttributeName value:[NSString stringWithFormat:@"%@ = %@", [tag tagName], [tag tagValue]] range:tagCharRange];
            
            [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlinePatternDot] range:tagCharRange];
        }
        tokenIndex++;
    }
    
    //[space release];
	
	[[self textStorage] setAttributedString:attributedString];
    
    [attributedString release];
}

@end
