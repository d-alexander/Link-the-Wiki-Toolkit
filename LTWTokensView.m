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

-(void)_addTagsForTokens:(LTWTokens*)theTokens toAttributedString:(NSMutableAttributedString*)attributedString {
    
    for (NSValue *value in [theTokens tagRanges]) {
        NSRange tagTokenRange = [value rangeValue];
        for (LTWTokenTag *tag in [theTokens tagsWithRange:tagTokenRange]) {
            NSRange firstTokenCharRange = [theTokens rangeOfTokenAtIndex:tagTokenRange.location];
            NSRange lastTokenCharRange = [theTokens rangeOfTokenAtIndex:NSMaxRange(tagTokenRange)-1];
            NSRange tagCharRange = NSMakeRange(firstTokenCharRange.location, NSMaxRange(lastTokenCharRange) - firstTokenCharRange.location);
            
            [attributedString addAttribute:NSToolTipAttributeName value:[NSString stringWithFormat:@"%@ = %@", [tag tagName], [tag tagValue]] range:tagCharRange];
            
            [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlinePatternDot] range:tagCharRange];
        }
    }
}

-(void)tokenTagsChanged:(NSNotification*)notification {
	[[self textStorage] setAttributes:[NSDictionary dictionary] range:NSMakeRange(0, [[self textStorage] length])];
	[self _addTagsForTokens:tokens toAttributedString:[self textStorage]];
}

-(void)setTokens:(LTWTokens*)theTokens {
	[tokens release];
	tokens = [theTokens retain];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenTagsChanged:) name:LTWTokenTagsChangedNotification object:theTokens];
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[theTokens _text]];
	
	[self _addTagsForTokens:theTokens toAttributedString:attributedString];
	
	[[self textStorage] setAttributedString:attributedString];
}

@end
