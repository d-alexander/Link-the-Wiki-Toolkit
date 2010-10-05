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

    const int year = 1;
    
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
            
            NSLog(@"got token %@", tokenString);
             
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
                    break;
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
                NSLog(@"adding link with offset=%d, length=%d", offset, length);
                for (NSUInteger articleTokenIndex = 0; articleTokenIndex < [articleTokens count]; articleTokenIndex++) {
                    NSRange articleTokenRange = [articleTokens rangeOfTokenAtIndex:articleTokenIndex];
                    if (NSMaxRange(articleTokenRange) > offset) {
                        NSUInteger firstTokenIndex = articleTokenIndex;
                        while (NSMaxRange(articleTokenRange) < offset + length) {
                            articleTokenIndex++;
                            articleTokenRange = [articleTokens rangeOfTokenAtIndex:articleTokenIndex];
                        }
                        [articleTokens _addTag:[[[LTWTokenTag alloc] initWithName:@"linked_to" value:target] autorelease] fromIndex:firstTokenIndex toIndex:articleTokenIndex];
                        NSLog(@"link added from token %d to token %d", firstTokenIndex, articleTokenIndex);
                        break;
                    }
                }
            }
        }
        [[LTWDatabase sharedInstance] commit];
        [loopPool drain];
        
        [LTWDatabase stopAsynchronousThread];
            
        
    }else if (year == 2009) {
        [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"run_converter_output.db"]];
        
        LTWCorpus *corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/Wikipedia2009.py"]]];
        
        NSString *xml = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Downloads/2009-official-link-the-wiki/923.xml"]];
        
        LTWTokens *tokens = [[LTWTokens alloc] initWithXML:xml];
        
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        [[LTWDatabase sharedInstance] beginTransaction];
        
        NSUInteger tokenIndex = 0;
        NSRange tokenRange;
        NSString *currentSourceID = @"";
        LTWArticle *currentSourceArticle = nil;
        BOOL outgoing = NO;
        NSRange currentAnchor = NSMakeRange(NSNotFound, 0);
        NSUInteger currentBEP;
        BOOL inBEP = NO;
        NSUInteger articlesProcessed = 0;
        while ((tokenRange = [tokens rangeOfTokenAtIndex:tokenIndex]).location != NSNotFound) {
            NSString *tokenString = [[tokens _text] substringWithRange:tokenRange];
            BOOL isEndTag = [tokens tagWithName:@"isEndTag" startingAtTokenIndex:tokenIndex] != nil;
            BOOL isStartTag = !isEndTag && [tokens tagWithName:@"isXML" startingAtTokenIndex:tokenIndex] != nil;

            if (isStartTag && [tokenString isEqual:@"topic"]) {
                currentSourceID = [[[tokens tagWithName:@"attributeFile" startingAtTokenIndex:tokenIndex] tagValue] stringByAppendingString:@".xml"];
                if (currentSourceArticle) {
                    for (NSString *fieldName in [currentSourceArticle fieldNames]) {
                        [[currentSourceArticle tokensForField:fieldName] saveToDatabase];
                    }
                }
                
                printf("%s\n", [currentSourceID UTF8String]);
                
                currentSourceArticle = [corpus loadArticleWithURL:[NSURL URLWithString:[@"file:///Users/david/Desktop/phd/wp2009/allpages/" stringByAppendingPathComponent:currentSourceID]]];
                
                if (++articlesProcessed % 100 == 0) {
                    NSLog(@"%lu articles processed", articlesProcessed);
                    [[LTWDatabase sharedInstance] commit];
                    [[LTWDatabase sharedInstance] beginTransaction];
                    [loopPool drain];
                    loopPool = [[NSAutoreleasePool alloc] init];
                    break;
                }
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
                if (outgoing) {
                    printf("%s.xml\n", [tokenString UTF8String]);
                    NSUInteger offset = currentAnchor.location;
                    NSUInteger length = currentAnchor.length;
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
            
            tokenIndex++;
        }
        
        [[LTWDatabase sharedInstance] commit];
        [loopPool drain];
        
        [LTWDatabase stopAsynchronousThread];
    }else if (year == 2010) {
        __block LTWBufferedParser *runFileParser = [[LTWBufferedParser alloc] init];
        [runFileParser addTextTagsWithNames:[NSArray arrayWithObject:@"field"]];
        
        [runFileParser setFile:@"/Users/david/Desktop/phd/te_ara/xml.xml"];
        
        __block NSString *tokenString;
        __block NSMutableDictionary *extraInfo = [[NSMutableDictionary alloc] init];
        __block BOOL isXML = NO, isStartTag = NO, isEndTag = NO;
        __block NSString *nameAttr = nil;
        __block NSUInteger INEXOffset = 0;
        BOOL (^getTokenFromRunFile)() = ^{
            
            NSRange tokenRange = [runFileParser getNextTokenWithExtraInfo:extraInfo];
            if (tokenRange.location == NSNotFound) return NO;
            tokenString = [runFileParser substringWithRange:tokenRange];
            isXML = [extraInfo objectForKey:@"isXML"] != nil;
            isEndTag = isXML && [extraInfo objectForKey:@"isEndTag"] != nil;
            isStartTag = isXML && !isEndTag;
            nameAttr = [extraInfo objectForKey:@"attributeName"];
            INEXOffset = [[extraInfo objectForKey:@"INEXOffset"] intValue];
            
            return YES;
        };
        
        NSString *currentNid;
        BOOL inBody;
        
        NSMutableArray *searches = [NSMutableArray array];
        //[searches addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"project",@"word", @"187", @"nid", nil]];
        [searches addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"balloons",@"word", @"9638", @"nid", nil]];
        [searches addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"p",@"word", @"10151", @"nid", nil]];
        [searches addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Diving",@"word", @"12991", @"nid", nil]];
        [searches addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"p",@"word", @"14270", @"nid", nil]];
        [searches addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"p",@"word", @"10208", @"nid", nil]];
        [searches addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"p",@"word", @"9363", @"nid", nil]];
        
        while (getTokenFromRunFile()) {
            if (isStartTag && [tokenString isEqual:@"field"]) {
                if ([nameAttr isEqual:@"nid"]) {
                    getTokenFromRunFile();
                    currentNid = tokenString;
                }else if ([nameAttr isEqual:@"body"]) {
                    inBody = YES;
                }
            }else if (isEndTag && [tokenString isEqual:@"field"]) {
                inBody = NO;
            }
            if (inBody) {
                for (NSMutableDictionary *search in searches) {
                    if ([search objectForKey:@"offset"] == nil && [[search objectForKey:@"nid"] isEqual:currentNid] && [[search objectForKey:@"word"] isEqual:tokenString]) {
                        [search setObject:[NSNumber numberWithInt:INEXOffset] forKey:@"offset"];
                        break;
                    }
                }
            }
        }
        
        NSLog(@"searches = %@", searches);

    }else if (year == 0) {
        
        [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"te_ara_index.db"]];
        
        [[LTWDatabase sharedInstance] beginTransaction];
        
        LTWCorpus *corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/TeAra.py"]]];
        
        NSUInteger articlesProcessed = 0;
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        
        for (NSString *urlString in [corpus articleURLs]) {
            LTWArticle *article = [corpus loadArticleWithURL:[NSURL URLWithString:urlString]];
            
            /*
            for (NSString *fieldName in [article fieldNames]) {
                [[article tokensForField:fieldName] saveToDatabase];
            }
             */
            [article pageOut];
            
            if (++articlesProcessed % 100 == 0) {
                NSLog(@"%u articles processed", articlesProcessed);
                [[LTWDatabase sharedInstance] commit];
                [[LTWDatabase sharedInstance] beginTransaction];
                [loopPool drain];
                loopPool = [[NSAutoreleasePool alloc] init];
            }
        }
        
        [[LTWDatabase sharedInstance] commit];
        [LTWDatabase stopAsynchronousThread];
        [loopPool drain];
    }else if (year == 1) {
        
        [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"wikipedia_index.db"]];
        
        [[LTWDatabase sharedInstance] beginTransaction];
        
        LTWCorpus *corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/Wikipedia.py"]]];
        
        NSUInteger articlesProcessed = 0;
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        
        for (NSString *urlString in [corpus articleURLs]) {
            LTWTokens *tokens = [[LTWTokens alloc] initWithXML:[NSString stringWithContentsOfURL:[NSURL URLWithString:urlString]]];
            
            [tokens saveToDatabase];
            [tokens release];
            
            if (++articlesProcessed % 100 == 0) {
                NSLog(@"%u articles processed", articlesProcessed);
                [[LTWDatabase sharedInstance] commit];
                [[LTWDatabase sharedInstance] beginTransaction];
                [loopPool drain];
                loopPool = [[NSAutoreleasePool alloc] init];
            }
        }
        
        [[LTWDatabase sharedInstance] commit];
        [LTWDatabase stopAsynchronousThread];
        [loopPool drain];

        
    }
    
    [pool drain];
    return 0;
}

