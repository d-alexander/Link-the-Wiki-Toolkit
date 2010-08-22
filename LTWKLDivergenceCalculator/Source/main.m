//
//  main.m
//  LTWKLDivergenceCalculator
//
//  Created by David Alexander on 18/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "LTWTokens.h"

@interface LTWPosting : NSObject {
    NSString *articleName;
    NSUInteger articleLength;
}
@property (readonly) NSString *articleName;
@property (readonly) NSUInteger articleLength;
@end
@implementation LTWPosting
@synthesize articleName;
@synthesize articleLength;
-(BOOL)isEqual:(id)object {
    return [object isKindOfClass:[LTWPosting class]] && [((LTWPosting*)object)->articleName isEqual:articleName] && ((LTWPosting*)object)->articleLength == articleLength;
}
-(NSUInteger)hash {
    return [articleName hash];
}
+(LTWPosting*)postingWithName:(NSString*)name length:(NSUInteger)length {
    LTWPosting *posting = [[LTWPosting alloc] init];
    posting->articleName = [name retain];
    posting->articleLength = length;
    return [posting autorelease];
}
-(id)copyWithZone:(NSZone*)zone {
    return [self retain];
}
@end

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSDirectoryEnumerator *enumerator = nil;
    NSString *filename;
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSUInteger filesProcessed = 0;
    for (enumerator = [[NSFileManager defaultManager] enumeratorAtPath:@"/Users/david/Desktop/phd/te_ara/articles/"];
         filename = [enumerator nextObject]; ) {
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        
        LTWTokens *tokens = [[[LTWTokens alloc] initWithXML:[NSString stringWithContentsOfFile:[@"/Users/david/Desktop/phd/te_ara/articles/" stringByAppendingString:filename]]] autorelease];
        NSUInteger numTokens = [tokens count];
        NSString *tokensText = [tokens _text];
        
        LTWPosting *posting = [LTWPosting postingWithName:filename length:numTokens];
        
        for (NSUInteger tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
            NSRange tokenRange = [tokens rangeOfTokenAtIndex:tokenIndex];
            // Should check for XML tags here.
            NSString *tokenString = [tokensText substringWithRange:tokenRange];
            NSCountedSet *postings = [dictionary objectForKey:tokenString];
            if (!postings) {
                postings = [NSCountedSet set];
                [dictionary setObject:postings forKey:tokenString];
            }
            [postings addObject:posting];
        }
        
        if (++filesProcessed % 1000 == 0) NSLog(@"%u files processed.", filesProcessed);
        
        [loopPool release];
    }
    
    /*
     Each iteration of the following loop, divergencesForCurrentWPDocument stores the KL-divergences between the current Wikipedia document and all of the Te Ara documents.
     */
    NSMutableDictionary *divergencesForCurrentWPDocument = [NSMutableDictionary dictionaryWithCapacity:filesProcessed];
    
    for (enumerator = [[NSFileManager defaultManager] enumeratorAtPath:@"/Users/david/Desktop/phd/wp2007/"];
         filename = [enumerator nextObject]; ) {
        
        [divergencesForCurrentWPDocument removeAllObjects];
        
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        
        LTWTokens *tokens = [[[LTWTokens alloc] initWithXML:[NSString stringWithContentsOfFile:[@"/Users/david/Desktop/phd/wp2007/" stringByAppendingString:filename]]] autorelease];
        NSUInteger numTokens = [tokens count];
        NSString *tokensText = [tokens _text];
        
        NSCountedSet *articleWords = [NSCountedSet set];
        
        for (NSUInteger tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
            NSRange tokenRange = [tokens rangeOfTokenAtIndex:tokenIndex];
            // Should check for XML tags here.
            NSString *tokenString = [tokensText substringWithRange:tokenRange];
            [articleWords addObject:tokenString];
        }
        
        for (NSString *word in articleWords) {
            NSUInteger wordFrequencyInWPDocument = [articleWords countForObject:word];
            NSCountedSet *postingsForWord = [dictionary objectForKey:word];
            if (!postingsForWord) continue;
            
            for (LTWPosting *posting in postingsForWord) {
                NSNumber *divergence = [divergencesForCurrentWPDocument objectForKey:posting];
                if (!divergence) divergence = [NSNumber numberWithDouble:0.0];
                
                double probabilityInTADocument = ([postingsForWord countForObject:posting] / [posting articleLength]);
                double probabilityInWPDocument = (wordFrequencyInWPDocument / numTokens);
                double newTerm = probabilityInTADocument * log2(probabilityInTADocument / probabilityInWPDocument);
                
                divergence = [NSNumber numberWithDouble:([divergence doubleValue] + newTerm)];
                [divergencesForCurrentWPDocument setObject:divergence forKey:posting];
            }
        }
        
        
        
        if (++filesProcessed % 1000 == 0) NSLog(@"%u files processed.", filesProcessed);
        
        [loopPool release];
    }
    
    [pool drain];
    return 0;
}

