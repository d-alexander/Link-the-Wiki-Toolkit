//
//  main.m
//  LTWRunConverter
//
//  Created by David Alexander on 29/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "LTWTokens.h"
#import "LTWCorpus.h"
#import "LTWBufferedParser.h"

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    const int year = 2008;
    
    if (year == 2008) {
        [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"run_converter_output.db"]];
        
        LTWCorpus *corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/Wikipedia.py"]]];

        
        
        __block LTWBufferedParser *runFileParser = [[LTWBufferedParser alloc] init];
    
        [runFileParser setFile:@"/Users/david/Desktop/phd/LTW2008/Otago/OtagocapConstantSingleSearch.xml"];
        
        __block NSString *tokenString;
        __block NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        __block BOOL isXML = NO, isStartTag = NO, isEndTag = NO;
        BOOL (^getTokenFromRunFile)() = ^{
            
            NSRange tokenRange = [runFileParser getNextTokenWithExtraInfo:extraInfo];
            if (tokenRange.location == NSNotFound) return NO;
            tokenString = [runFileParser substringWithRange:tokenRange];
            isXML = [extraInfo objectForKey:@"isXML"] != nil;
            isEndTag = isXML && [extraInfo objectForKey:@"isEndTag"] != nil;
            isStartTag = isXML && !isEndTag;
             
            return YES;
        };
        
        NSString *currentSourceID = @"";
        LTWArticle *currentSourceArticle = nil;
        BOOL outgoing = NO;
        
        NSUInteger articlesProcessed = 0;
        
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        
        [[LTWDatabase sharedInstance] beginTransaction];
        
        while (getTokenFromRunFile()) {
            if (isStartTag && [tokenString isEqual:@"topic"]) {
                currentSourceID = [extraInfo objectForKey:@"attributeFile"];
                if (currentSourceArticle) {
                    for (NSString *fieldName in [currentSourceArticle fieldNames]) {
                        [[currentSourceArticle tokensForField:fieldName] saveToDatabase];
                    }
                }
                currentSourceArticle = [corpus loadArticleWithURL:[NSURL URLWithString:[@"file:///Users/david/Desktop/phd/wp2007/" stringByAppendingPathComponent:currentSourceID]]];
                
                [loopPool drain];
                
                loopPool = [[NSAutoreleasePool alloc] init];
                
                if (++articlesProcessed % 100 == 0) {
                    NSLog(@"%lu articles processed", articlesProcessed);
                    [[LTWDatabase sharedInstance] commit];
                    [[LTWDatabase sharedInstance] beginTransaction];
                }
            }else if (isStartTag && [tokenString isEqual:@"outgoing"]) {
                outgoing = YES;
            }else if (isStartTag && [tokenString isEqual:@"incoming"]) {
                outgoing = NO;
            }else if (isStartTag && [tokenString isEqual:@"link"] && outgoing) {
                while (getTokenFromRunFile() && isXML);
                while (!isXML && getTokenFromRunFile());
                while (getTokenFromRunFile() && isXML);
                NSUInteger offset = [tokenString intValue];
                while (getTokenFromRunFile() && isXML);
                NSUInteger length = [tokenString intValue];
                while (getTokenFromRunFile() && isXML);
                NSString *target = tokenString;
                
                LTWTokens *articleTokens = [currentSourceArticle tokensForField:@"body"];
                for (NSUInteger articleTokenIndex = 0; articleTokenIndex < [articleTokens count]; articleTokenIndex++) {
                    NSRange articleTokenRange = [articleTokens rangeOfTokenAtIndex:articleTokenIndex];
                    if (NSMaxRange(articleTokenRange) > offset) {
                        NSUInteger firstTokenIndex = articleTokenIndex;
                        while (NSMaxRange(articleTokenRange) < offset + length) {
                            articleTokenIndex++;
                            articleTokenRange = [articleTokens rangeOfTokenAtIndex:articleTokenIndex];
                        }
                        [articleTokens _addTag:[[[LTWTokenTag alloc] initWithName:@"linked_to" value:target] autorelease] fromIndex:firstTokenIndex toIndex:articleTokenIndex];
                        break;
                    }
                }
            }
        }
        [[LTWDatabase sharedInstance] commit];
        [loopPool drain];
            
        
    }else if (year == 2009) {
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
                // TODO: Discriminate between outgoing and incoming links.
                printf("%s:%d:ANCHOR_TEXT_HERE %s:%d\n", [currentSourceID UTF8String], currentAnchor.location, [tokenString UTF8String], currentBEP);
            }
            
            tokenIndex++;
        }
    }
    
    [pool drain];
    return 0;
}

