//
//  LTWParser.h
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 NOTE: This class is taken directly from the old version of the LTW toolkit. It could use some rewriting, especially of the interface.
 */
@interface LTWParser : NSObject {
	NSString *xml;
	NSUInteger current;
}

typedef enum {
	XML_START_TAG = 1, XML_END_TAG = 2
} LTWTokenType;

-(void)setDocumentText:(NSString*)text;
-(NSRange)getNextTokenWithExtraInfo:(NSMutableDictionary *)extraInfo tokenType:(LTWTokenType*)tokenType;
-(NSRange)getNextTokenWithExtraInfo:(NSMutableDictionary*)extraInfo;
-(NSRange)getNextTokenWithTokenType:(LTWTokenType*)tokenType;
-(NSRange)getNextToken;
-(NSRange)getTokenUpToCharacter:(unichar)character;
-(NSString*)substringWithRange:(NSRange)range;

@end
