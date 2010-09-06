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

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    const int year = 2008;
    
    if (year == 2008) {
        [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"run_converter_output.db"]];
        
        LTWCorpus *corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/Wikipedia.py"]]];

        LTWTokens *runFileTokens = [[LTWTokens alloc] initWithXML:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Desktop/phd/LTW2008/Otago/OtagocapConstantSingleSearch.xml"]]];
        
        
        NSUInteger tokenIndex = 0;
        NSRange tokenRange;
        NSString *currentSourceID = @"";
        LTWArticle *currentSourceArticle = nil;
        BOOL outgoing = NO;
        while ((tokenRange = [runFileTokens rangeOfTokenAtIndex:tokenIndex]).location != NSNotFound) {
            NSString *tokenString = [[runFileTokens _text] substringWithRange:tokenRange];
            BOOL isEndTag = [runFileTokens tagWithName:@"isEndTag" startingAtTokenIndex:tokenIndex] != nil;
            BOOL isStartTag = !isEndTag && [runFileTokens tagWithName:@"isXML" startingAtTokenIndex:tokenIndex] != nil;
            
            if (isStartTag && [tokenString isEqual:@"topic"]) {
                currentSourceID = [[runFileTokens tagWithName:@"attributeFile" startingAtTokenIndex:tokenIndex] tagValue];
                if (currentSourceArticle) {
                    for (NSString *fieldName in [currentSourceArticle fieldNames]) {
                        [[currentSourceArticle tokensForField:fieldName] saveToDatabase];
                    }
                }
                currentSourceArticle = [corpus loadArticleWithURL:[NSURL URLWithString:[@"file:///Users/david/Desktop/phd/wp2007/" stringByAppendingString:currentSourceID]]];
            }else if (isStartTag && [tokenString isEqual:@"outgoing"]) {
                outgoing = YES;
            }else if (isStartTag && [tokenString isEqual:@"incoming"]) {
                outgoing = NO;
            }else if (isStartTag && [tokenString isEqual:@"link"]) {
                do tokenIndex++; while ([runFileTokens tagWithName:@"isXML" startingAtTokenIndex:tokenIndex] != nil);
                do tokenIndex++; while ([runFileTokens tagWithName:@"isXML" startingAtTokenIndex:tokenIndex] != nil);
                NSUInteger offset = [[[runFileTokens _text] substringWithRange:[runFileTokens rangeOfTokenAtIndex:tokenIndex]] intValue];
                do tokenIndex++; while ([runFileTokens tagWithName:@"isXML" startingAtTokenIndex:tokenIndex] != nil);
                NSUInteger length = [[[runFileTokens _text] substringWithRange:[runFileTokens rangeOfTokenAtIndex:tokenIndex]] intValue];
                
                do tokenIndex++; while ([runFileTokens tagWithName:@"isXML" startingAtTokenIndex:tokenIndex] != nil);
                NSString *target = [[runFileTokens _text] substringWithRange:[runFileTokens rangeOfTokenAtIndex:tokenIndex]];
                
                LTWTokens *articleTokens = [currentSourceArticle tokensForField:@"body"];
                for (NSUInteger articleTokenIndex = 0; articleTokenIndex < [articleTokens count]; articleTokenIndex++) {
                    NSRange articleTokenRange = [articleTokens rangeOfTokenAtIndex:articleTokenIndex];
                    if (NSMaxRange(articleTokenRange) > offset) {
                        NSUInteger firstTokenIndex = articleTokenIndex;
                        while (NSMaxRange(articleTokenRange) < offset + length) {
                            articleTokenIndex++;
                            articleTokenRange = [articleTokens rangeOfTokenAtIndex:articleTokenIndex];
                        }
                        
                        // TEMP
                        NSLog(@"LINK:");
                        for (NSUInteger i=firstTokenIndex; i<=articleTokenIndex; i++) {
                            NSLog(@"\t%@ ", [[articleTokens _text] substringWithRange:[articleTokens rangeOfTokenAtIndex:i]]);
                        }
                    }
                }
                
                /*
                 TODO:
                  - For each source article, load the LTWArticle from disk.
                  - For each link, find the token range associated with a given FOL and tag it as a link to the specified target. The target article needn't be loaded.
                  - At the end of each source, save the article to the database.
                 */
            }
            
            tokenIndex++;
        }
        
        
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

