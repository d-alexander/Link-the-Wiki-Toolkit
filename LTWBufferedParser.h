//
//  LTWBufferedParser.h
//  LTWToolkit
//
//  Created by David Alexander on 8/09/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LTWParser.h"

@interface LTWBufferedParser : LTWParser {
    FILE *inputFile;
    NSRange bufferRangeInFile;
    NSUInteger ensuredCharacterIndex;
    NSString *buffer;
}

-(void)setFile:(NSString*)filename;

@end
