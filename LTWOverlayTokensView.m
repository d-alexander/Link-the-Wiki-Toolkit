//
//  LTWOverlayTokensView.m
//  LTWToolkit
//
//  Created by David Alexander on 13/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWOverlayTokensView.h"

@implementation LTWOverlayRect

@synthesize frame;

-(id)initWithTextView:(NSTextView*)theTextView characterRange:(NSRange)theCharacterRange {
    if (self = [super init]) {
        textView = [theTextView retain];
        characterRange = theCharacterRange;
        
        NSRange glyphRange = [[textView layoutManager] glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
        frame = [[textView layoutManager]  boundingRectForGlyphRange:glyphRange inTextContainer:[textView textContainer]];
        
        rectType = DIRECT_COCOA;
        
    }
    return self;
}

#ifdef GTK_PLATFORM
-(id)initWithGtkTextView:(GtkTextView*)theTextView characterRange:(NSRange)theCharacterRange gdkRect:(GdkRectangle)theRect {
    if (self = [super init]) {
        // NOTE: When we adopt GTK's reference-counting, we need to do the equivalent of "retain" here. (And lots of other places, but they'll mostly be in LTWGTKPlatorm.)
        gtkTextView = theTextView;
        
        characterRange = theCharacterRange;
        frame = NSMakeRect(theRect.x, theRect.y, theRect.width, theRect.height);
    }
    return self;
}
#endif

-(NSRect)frame {
    return frame;
}

@end

@implementation LTWOverlayLayer

-(id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setAlphaValue:0.5];
    }
    return self;
}
    
-(void)drawRect:(NSRect)rect {
    [[NSColor redColor] set];
    NSRectFill([self bounds]);
}

-(BOOL)isFlipped {
    return YES;
}

@end

@implementation LTWOverlayTokensView

-(NSRange)charRangeForTokensFromIndex:(NSUInteger)firstTokenIndex toIndex:(NSUInteger)lastTokenIndex {
    NSRange firstTokenRange = NSMakeRange(NSNotFound, 0);
    NSRange lastTokenRange = NSMakeRange(NSNotFound, 0);
    
    while (true) {
        NSValue *rangeValue = [nonXMLTokenRanges objectForKey:[NSNumber numberWithInt:firstTokenIndex]];
        if (rangeValue) {
            firstTokenRange = [rangeValue rangeValue];
            break;
        }
        if (firstTokenIndex > lastTokenIndex) return NSMakeRange(NSNotFound, 0);
        
        firstTokenIndex++;
    }
    
    while (true) {
        NSValue *rangeValue = [nonXMLTokenRanges objectForKey:[NSNumber numberWithInt:lastTokenIndex]];
        if (rangeValue) {
            lastTokenRange = [rangeValue rangeValue];
            break;
        }
        if (firstTokenIndex > lastTokenIndex) return NSMakeRange(NSNotFound, 0);
        
        lastTokenIndex--;
    }
    
    return NSMakeRange(firstTokenRange.location, NSMaxRange(lastTokenRange) - firstTokenRange.location);
}

-(LTWOverlayRect*)rectForTokensFromIndex:(NSUInteger)firstTokenIndex toIndex:(NSUInteger)lastTokenIndex {
    NSRange charRange = [self charRangeForTokensFromIndex:firstTokenIndex toIndex:lastTokenIndex];
    
    // TEMP
    [self collapseTokensFromIndex:(lastTokenIndex+1) toIndex:(lastTokenIndex+2)];
    
    return [[[LTWOverlayRect alloc] initWithTextView:self characterRange:charRange] autorelease];
}

-(void)addOverlayWithRect:(LTWOverlayRect*)overlayRect text:(NSString*)text {
    LTWOverlayLayer *layer = [[LTWOverlayLayer alloc] initWithFrame:[overlayRect frame]];
    [self addSubview:layer];
    [overlayLayers addObject:layer];
    [layer release];
}

-(void)collapseTokensFromIndex:(NSUInteger)firstTokenIndex toIndex:(NSUInteger)lastTokenIndex {
    NSRange charRange = [self charRangeForTokensFromIndex:firstTokenIndex toIndex:lastTokenIndex];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    [attachment setAttachmentCell:[[NSTextAttachmentCell alloc] init]];
    [[self textStorage] addAttribute:NSAttachmentAttributeName value:attachment range:charRange];
    [[self textStorage] addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:charRange];
    //[attachment release];
    [self didChangeText];
}

-(id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
    }
    
    return self;
}

-(void)awakeFromNib {
    overlayLayers = [[NSMutableArray alloc] init];
    [super awakeFromNib];
}

-(NSData*)dataForTokens:(LTWTokens*)theTokens {
    NSMutableData *data = [NSMutableData data];
    
    NSUInteger tokenIndex = 0;
    for (NSValue *rangeValue in theTokens) {
        NSRange tokenRange = [rangeValue rangeValue];
        
        BOOL isXMLTag = NO;
        
        for (LTWTokenTag *tag in [theTokens tagsStartingAtTokenIndex:tokenIndex]) {
            if ([[tag tagName] isEqual:@"tagStartOffset"]) {
                isXMLTag = YES;
                tokenRange.location -= [[tag tagValue] intValue];
            }
            if ([[tag tagName] isEqual:@"tagLength"]) {
                isXMLTag = YES;
                tokenRange.length = [[tag tagValue] intValue];
            }
        }
        
        NSString *tokenString = [[[theTokens _text] substringWithRange:tokenRange] stringByDecodingXMLEntities];
        
        if (isXMLTag) {
            [data appendData:[[NSString stringWithFormat:@"%@ ",tokenString] dataUsingEncoding:NSUTF8StringEncoding]];
        }else{
            [data appendData:[[NSString stringWithFormat:@"<a href='tokenindex://token#%d'>%@</a> ",tokenIndex,tokenString] dataUsingEncoding:NSUTF8StringEncoding]];
        }
            
        tokenIndex++;
    }
    
    return data;
}

-(NSDictionary*)extractRangesFromAttributedString:(NSMutableAttributedString*)attributedString {
    NSUInteger charIndex = 0;
    NSMutableDictionary *tokenRanges = [NSMutableDictionary dictionary];
    
    [attributedString fixAttributesInRange:NSMakeRange(0, [attributedString length])];
    
    while (charIndex < [attributedString length]) {
        NSRange effectiveRange;
        id value = [attributedString attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:&effectiveRange];
        if (value) {
            NSString *str = [value description];
            NSRange tokenHashRange = [str rangeOfString:@"token#"];
            if (tokenHashRange.location != NSNotFound) {
                NSUInteger tokenIndex = [[str substringFromIndex:NSMaxRange(tokenHashRange)] intValue];
                
                NSValue *rangeValue = [tokenRanges objectForKey:[NSNumber numberWithInt:tokenIndex]];
                if (!rangeValue) {
                    rangeValue = [NSValue valueWithRange:effectiveRange];
                }else{
                    rangeValue = [NSValue valueWithRange:NSMakeRange([rangeValue rangeValue].location, NSMaxRange(effectiveRange) - [rangeValue rangeValue].location)];
                }
                [tokenRanges setObject:rangeValue forKey:[NSNumber numberWithInt:tokenIndex]];
                
                [attributedString removeAttribute:NSLinkAttributeName range:effectiveRange];
                [attributedString removeAttribute:NSForegroundColorAttributeName range:effectiveRange];
                [attributedString removeAttribute:NSUnderlineStyleAttributeName range:effectiveRange];
            }
        }
        charIndex = NSMaxRange(effectiveRange);
    }
    
    [attributedString fixAttributesInRange:NSMakeRange(0, [attributedString length])];
    
    return tokenRanges;
}

-(void)setTokens:(LTWTokens*)theTokens {
    
    for (LTWOverlayLayer *layer in overlayLayers) {
        [layer removeFromSuperview];
    }
    [overlayLayers removeAllObjects];
    
    if (theTokens != tokens) {
        [tokens release];
        tokens = [theTokens retain];
    }
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenTagsChanged:) name:LTWTokenTagsChangedNotification object:theTokens];
    
    /*
     Current procedure for loading new tokens into view:
      - Concatenate the tokens together into an NSData. (NOTE: Currently not including HTML tags properly!)
      - Convert the NSData (interpreted as HTML) to an NSAttributedString, storing tag indices in <a> tags so that they will be transferred into the attributed string.
      - Extract the ranges of the individual tokens from the <a> tags.
      - Create overlays for all token-tags.
     */
    
    NSData *data = [self dataForTokens:theTokens];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithHTML:data documentAttributes:NULL];
    nonXMLTokenRanges = [[self extractRangesFromAttributedString:attributedString] retain];
    
	[[self textStorage] setAttributedString:attributedString];
    
    [attributedString release];
    
    for (NSUInteger tokenIndex = 0; tokenIndex < [theTokens count]; tokenIndex++) {
        for (LTWTokenTag *tag in [theTokens tagsStartingAtTokenIndex:tokenIndex]) {
            LTWOverlayRect *rect = [self rectForTokensFromIndex:tokenIndex toIndex:tokenIndex];
            [self addOverlayWithRect:rect text:@"(LINK)"];
        }
    }
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

@end

@implementation NSString (XMLEntityDecoding)

/*
 Taken from http://stackoverflow.com/questions/1105169/html-character-decoding-in-objective-c-cocoa-touch
 */
- (NSString *)stringByDecodingXMLEntities {
    NSUInteger myLength = [self length];
    NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;
    
    // Short-circuit if there are no ampersands.
    if (ampIndex == NSNotFound) {
        return self;
    }
    // Make result string with some extra capacity.
    NSMutableString *result = [NSMutableString stringWithCapacity:(myLength * 1.25)];
    
    // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
    NSScanner *scanner = [NSScanner scannerWithString:self];
    
    [scanner setCharactersToBeSkipped:nil];
    
    NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
    
    do {
        // Scan up to the next entity or the end of the string.
        NSString *nonEntityString;
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        if ([scanner isAtEnd]) {
            goto finish;
        }
        // Scan either a HTML or numeric character entity reference.
        if ([scanner scanString:@"&amp;" intoString:NULL])
            [result appendString:@"&"];
        else if ([scanner scanString:@"&apos;" intoString:NULL])
            [result appendString:@"'"];
        else if ([scanner scanString:@"&quot;" intoString:NULL])
            [result appendString:@"\""];
        else if ([scanner scanString:@"&lt;" intoString:NULL])
            [result appendString:@"<"];
        else if ([scanner scanString:@"&gt;" intoString:NULL])
            [result appendString:@">"];
        else if ([scanner scanString:@"&#" intoString:NULL]) {
            BOOL gotNumber;
            unsigned charCode;
            NSString *xForHex = @"";
            
            // Is it hex or decimal?
            if ([scanner scanString:@"x" intoString:&xForHex]) {
                gotNumber = [scanner scanHexInt:&charCode];
            }
            else {
                gotNumber = [scanner scanInt:(int*)&charCode];
            }
            
            if (gotNumber) {
                [result appendFormat:@"%C", charCode];
                
                [scanner scanString:@";" intoString:NULL];
            }
            else {
                NSString *unknownEntity = @"";
                
                [scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
                
                
                [result appendFormat:@"&#%@%@", xForHex, unknownEntity];
                
                //[scanner scanUpToString:@";" intoString:&unknownEntity];
                //[result appendFormat:@"&#%@%@;", xForHex, unknownEntity];
                NSLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
                
            }
            
        }
        else {
            NSString *amp;
            
            [scanner scanString:@"&" intoString:&amp];      //an isolated & symbol
            [result appendString:amp];
            
            /*
             NSString *unknownEntity = @"";
             [scanner scanUpToString:@";" intoString:&unknownEntity];
             NSString *semicolon = @"";
             [scanner scanString:@";" intoString:&semicolon];
             [result appendFormat:@"%@%@", unknownEntity, semicolon];
             NSLog(@"Unsupported XML character entity %@%@", unknownEntity, semicolon);
             */
        }
        
    }
    while (![scanner isAtEnd]);
    
finish:
    return result;
}


@end
