//
//  LTWBufferedParser.m
//  LTWToolkit
//
//  Created by David Alexander on 8/09/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWBufferedParser.h"


@implementation LTWBufferedParser

-(id)init {
    if (self = [super init]) {
        buffer = malloc(1024*1024*sizeof *buffer);
    }
    return self;
}

-(void)setDocumentText:(NSString*)theContents {
	NSAssert(NO, @"Trying to set the text of an LTWBufferedParser!");
}

-(void)setFile:(NSString*)filename {
    inputFile = fopen([filename UTF8String], "rb");
    bufferRangeInFile = NSMakeRange(0, 0);
    ensuredCharacterIndex = 0;
}

-(void)ensureCharactersAvailableFromIndex:(NSUInteger)startIndex {
    ensuredCharacterIndex = (startIndex == 0) ? 0 : (startIndex - 1); // in case we have to look at the previous character, which we sometimes do
}

wchar_t readUTF8Sequence(FILE *file) {
    unsigned char c;
    wchar_t wc = 0;
    
    if (fread(&c, sizeof c, 1, file) == 0) return 0;
    if (c < 0x80) {
        wc = c;
    }else if ((c & 0xE0) == 0xC0) {
        wc |= (c & 0x1F);
        fread(&c, sizeof c, 1, file);
        wc <<= 6;
        wc |= (c & 0x3F);
    }else if ((c & 0xF0) == 0xE0) {
        wc |= (c & 0x0F);
        fread(&c, sizeof c, 1, file);
        wc <<= 6;
        wc |= (c & 0x3F);
        fread(&c, sizeof c, 1, file);
        wc <<= 6;
        wc |= (c & 0x3F);
    }else if ((c & 0xF8) == 0xF0) {
        wc |= (c & 0x03);
        fread(&c, sizeof c, 1, file);
        wc <<= 6;
        wc |= (c & 0x3F);
        fread(&c, sizeof c, 1, file);
        wc <<= 6;
        wc |= (c & 0x3F);
        fread(&c, sizeof c, 1, file);
        wc <<= 6;
        wc |= (c & 0x3F);
    }else{
        wc = -1;
    }
    
    return wc;
}

-(unichar)charAt:(NSUInteger)pos {
    NSAssert(pos >= bufferRangeInFile.location, @"Trying to seek backwards in LTWBufferedParser!");
    
    while (pos >= NSMaxRange(bufferRangeInFile)) {
        
        if (bufferRangeInFile.location < ensuredCharacterIndex) {
            NSRange oldRange = bufferRangeInFile;
        
            bufferRangeInFile.location = ensuredCharacterIndex;
            bufferRangeInFile.length -= bufferRangeInFile.location - oldRange.location;
        
            memmove(buffer, buffer + (bufferRangeInFile.location - oldRange.location), bufferRangeInFile.length * sizeof buffer[0]);
        }
            
        wchar_t wc;
        do {
            wc = readUTF8Sequence(inputFile);
        } while (wc == -1);
        if (wc == 0) return '\0';
        buffer[bufferRangeInFile.length++] = wc;
    }
    
    return buffer[pos - bufferRangeInFile.location];
}

-(NSString*)substringWithRange:(NSRange)range {
    NSAssert(range.location >= ensuredCharacterIndex, @"Trying to seek backwards in LTWBufferedParser!");
    
    // Make sure we have all the characters of the desired substring.
    [self charAt:NSMaxRange(range)-1];
    
    return [[[NSString alloc] initWithBytes:(buffer + range.location - bufferRangeInFile.location) length:(range.length * sizeof buffer[0]) encoding:NSUTF32LittleEndianStringEncoding] autorelease];
    
}

@end
