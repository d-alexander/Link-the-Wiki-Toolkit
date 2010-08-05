//
//  main.m
//  LTWTeAraSplitter
//
//  Created by David Alexander on 5/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "LTWParser.h"

void writeToFile(NSString *text, NSString *articleID) {
    NSString *filename = [NSString stringWithFormat:@"file:///Users/david/Desktop/te_ara/articles/%@.xml", articleID];
    [text writeToURL:[NSURL URLWithString:filename] atomically:YES];
}

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString *xml = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Desktop/te_ara/xml.xml"]];
    LTWParser *parser = [[LTWParser alloc] init];
    [parser setDocumentText:xml];
    
    NSRange tokenRange;
    NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
    NSString *articleID = nil;
    NSMutableString *articleContents = [[NSMutableString alloc] init];
    BOOL nidInNextToken = NO;
    while ((tokenRange = [parser getNextTokenWithExtraInfo:extraInfo]).location != NSNotFound) {
        if ([extraInfo objectForKey:@"isXML"] != nil && [xml compare:@"row" options:NSCaseInsensitiveSearch range:tokenRange] == NSOrderedSame) {
            if (articleID != nil) {
                writeToFile(articleContents, articleID);
                [articleContents setString:@""];
                articleID = nil;
            }
            continue;
        }
        
        if ([extraInfo objectForKey:@"isXML"] != nil && [extraInfo objectForKey:@"attributeName"] != nil && [[extraInfo objectForKey:@"attributeName"] isEqual:@"nid"]) {
            nidInNextToken = YES;
        }else if (nidInNextToken) {
            articleID = [xml substringWithRange:tokenRange];
            nidInNextToken = NO;
        }
        
        NSRange actualRange = tokenRange;
        if ([extraInfo objectForKey:@"isXML"] != nil) {
            actualRange = [[extraInfo objectForKey:@"tagRange"] rangeValue];
        }
        
        [articleContents appendFormat:@"%@ ", [xml substringWithRange:actualRange]];
    }
    
    [pool drain];
    return 0;
}

