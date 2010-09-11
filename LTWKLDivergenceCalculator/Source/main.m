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
    
    NSDirectoryEnumerator *enumerator;
    NSString *filename;
    NSUInteger filesProcessed = 0;
    
    [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"wikipedia_index.ltw"]];
    [[LTWDatabase sharedInstance] beginTransaction];
    
    for (enumerator = [[NSFileManager defaultManager] enumeratorAtPath:@"/Users/david/Desktop/phd/wp2007/"];
         filename = [enumerator nextObject]; ) {
        
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        
        LTWTokens *tokens = [[LTWTokens alloc] initWithXML:[NSString stringWithContentsOfFile:[@"/Users/david/Desktop/phd/wp2007/" stringByAppendingString:filename]]];
        
        
        // PROCESS TOKENS, ADDING TO LEXICON AND ADDING TFS TO DATABASE
        
        //[tokens saveToDatabase];
        [tokens release];
        
        if (++filesProcessed % 100 == 0) {
            [[LTWDatabase sharedInstance] commit];
            [[LTWDatabase sharedInstance] beginTransaction];
            NSLog(@"%u files processed.", filesProcessed);
        }
        
        [loopPool release];
    }
    
    [[LTWDatabase sharedInstance] commit];
    
    [pool drain];
    return 0;
}

