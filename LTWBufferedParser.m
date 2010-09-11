//
//  LTWBufferedParser.m
//  LTWToolkit
//
//  Created by David Alexander on 8/09/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWBufferedParser.h"


@implementation LTWBufferedParser

-(void)setDocumentText:(NSString*)theContents {
	NSAssert(NO, @"Trying to set the text of an LTWBufferedParser!");
}

-(void)setFile:(NSString*)filename {
    inputFile = fopen([filename UTF8String], "rb");
    bufferRangeInFile = NSMakeRange(0, 0);
    ensuredCharacterIndex = 0;
}

-(void)ensureCharactersAvailableFromIndex:(NSUInteger)startIndex {
    ensuredCharacterIndex = startIndex;
}

-(unichar)charAt:(NSUInteger)pos {
    NSAssert(pos >= bufferRangeInFile.location, @"Trying to seek backwards in LTWBufferedParser!");
    
    if (pos >= NSMaxRange(bufferRangeInFile)) {
        static char tempBuffer[1024];
        
        NSInteger bytesRead = fread(tempBuffer, 1, sizeof tempBuffer, inputFile);
        
        if (bytesRead == 0) return '\0';
        
        NSString *leftoverBufferContents = buffer ? [buffer substringFromIndex:(ensuredCharacterIndex - bufferRangeInFile.location)] : @"";
        [buffer release];
        
        NSString *newContents = [[NSString alloc] initWithBytes:tempBuffer length:bytesRead encoding:NSUTF8StringEncoding];
        
        buffer = [[leftoverBufferContents stringByAppendingString:newContents] retain];
        
        [newContents release];
        
        bufferRangeInFile = NSMakeRange(ensuredCharacterIndex, [buffer length]);
    }
    
    return [buffer characterAtIndex:(pos - bufferRangeInFile.location)];
}

-(NSString*)substringWithRange:(NSRange)range {
    NSAssert(range.location >= ensuredCharacterIndex, @"Trying to seek backwards in LTWBufferedParser!");
    
    // Make sure we have all the characters of the desired substring.
    [self charAt:NSMaxRange(range)-1];
    
    return [buffer substringWithRange:NSMakeRange(range.location - bufferRangeInFile.location, range.length)];
    
}

@end
