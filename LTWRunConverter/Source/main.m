//
//  main.m
//  LTWRunConverter
//
//  Created by David Alexander on 29/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "LTWTokens.h"

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString *xml = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Downloads/2009-official-link-the-wiki/923.xml"]];
    
    LTWTokens *tokens = [[LTWTokens alloc] initWithXML:xml];
    
    NSUInteger tokenIndex = 0;
    NSRange tokenRange;
    NSString *currentSourceID = @"";
    BOOL outgoing = NO;
    NSRange currentAnchor = NSMakeRange(NSNotFound, 0);
    NSUInteger currentBEP;
    BOOL inBEP = NO;
    while ((tokenRange = [tokens rangeOfTokenAtIndex:tokenIndex]).location != NSNotFound) {
        NSString *tokenString = [[tokens _text] substringWithRange:tokenRange];
        BOOL isEndTag = [tokens tagWithName:@"isEndTag" startingAtTokenIndex:tokenIndex] != nil;
        BOOL isStartTag = !isEndTag && [tokens tagWithName:@"isXML" startingAtTokenIndex:tokenIndex] != nil;

        if (isStartTag && [tokenString isEqual:@"topic"]) {
            currentSourceID = [[tokens tagWithName:@"attributeFile" startingAtTokenIndex:tokenIndex] tagValue];
        }else if (isStartTag && [tokenString isEqual:@"outgoing"]) {
            outgoing = YES;
        }else if (isStartTag && [tokenString isEqual:@"incoming"]) {
            outgoing = NO;
        }else if (isStartTag && [tokenString isEqual:@"anchor"]) {
            currentAnchor = NSMakeRange([[[tokens tagWithName:@"attributeOffset" startingAtTokenIndex:tokenIndex] tagValue] intValue], [[[tokens tagWithName:@"attributeLength" startingAtTokenIndex:tokenIndex] tagValue] intValue]);
        }else if (isStartTag && [tokenString isEqual:@"tobep"]) {
            currentBEP = [[[tokens tagWithName:@"attributeOffset" startingAtTokenIndex:tokenIndex] tagValue] intValue];
            inBEP = YES;
        }else if (isEndTag && [tokenString isEqual:@"tobep"]) {
            inBEP = NO;
        }else if (inBEP && !isStartTag && !isEndTag && [tokenString intValue] != 0) {
            printf("%s:%d:ANCHOR_TEXT_HERE %s:%d\n", [currentSourceID UTF8String], currentAnchor.location, [tokenString UTF8String], currentBEP);
        }
        
        tokenIndex++;
    }
    
    [pool drain];
    return 0;
}

