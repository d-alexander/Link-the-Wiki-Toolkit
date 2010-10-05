//
//  LTWParser.m
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWParser.h"


@implementation LTWParser

-(id)init {
    if (self = [super init]) {
        textTagNames = [[NSMutableSet alloc] init];
        tagStack = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)setDocumentText:(NSString*)theContents {
	if (xml) [xml release];
	xml = [theContents retain];
	current = 0;
    textChars = 0;
}

-(void)addTextTagsWithNames:(NSArray*)tagNames {
    [textTagNames addObjectsFromArray:tagNames];
}

enum LTWXMLParserCharType {
	XML_PUNCT = 1, ALPHABETICAL = 2, NUMERICAL = 4, NON_BREAKING_PUNCT = 8, BREAKING_PUNCT = 16, XML_NAME_START = 32, XML_NAME = 64, XML_QUOTE = 128, END_OF_STRING = 256
};

-(void)ensureCharactersAvailableFromIndex:(NSUInteger)startIndex {
    // Implemented in LTWBufferParser.
}

-(unichar)charAt:(NSUInteger)pos {
	if (pos < 0 || pos >= [self->xml length]) {
		return '\0';
	}else{
		return [self->xml characterAtIndex:pos];
	}
}

-(NSString*)substringWithRange:(NSRange)range {
    return [self->xml substringWithRange:range];
}

-(BOOL)unicodeCharIsAlphabetical:(unichar)c {
	return (
			(c == 0x00C4)|| // Ä U+00C4 Latin capital letter A with diaeresis
			(c == 0x00D6)|| // Ö U+00D6 Latin capital letter O with diaeresis
			(c == 0x00DC)|| // Ü U+00DC Latin capital letter U with diaeresis
			//(c == 0x1E9E)|| // ẞ U+1E9E LATIN CAPITAL LETTER SHARP S
			(c == 0x00E4)|| // ä U+00E4 Latin small letter a with diaeresis
			(c == 0x00F6)|| // ö U+00F6 Latin small letter o with diaeresis
			(c == 0x00FC)|| // ü U+00FC Latin small letter u with diaeresis
			(c == 0x00DF)|| // ß U+00DF LATIN SMALL LETTER SHARP S
			(c == 0x0100)|| // A with macron
			(c == 0x0101)|| // a with macron
			(c == 0x0112)|| // E with macron
			(c == 0x0113)|| // e with macron
			(c == 0x012A)|| // I with macron
			(c == 0x012B)|| // i with macron
			(c == 0x014C)|| // O with macron
			(c == 0x014D)|| // o with macron
			(c == 0x016A)|| // U with macron
			(c == 0x016B)   // u with macron
			);
}

-(BOOL)charAt:(NSUInteger)pos hasType:(enum LTWXMLParserCharType)charType {
	
    unichar c = [self charAt:pos];
    
    if (c == '\0') {
        return (charType & END_OF_STRING) ? YES : NO;
    }
	
	if (charType & XML_PUNCT) {
		if (c == '<' || c == '>' || c == '&' || c == '/') return YES;
	}
	if (charType & ALPHABETICAL) {
		if (isalpha(c)) return YES;
		// This is a hack to get around the fact that the Te Ara collection sometimes uses '?' (ASCII 63) for characters with macrons!
		if (c == '?' && !isspace([self charAt:pos-1]) && !isspace([self charAt:pos+1])) return YES;
		if ([self unicodeCharIsAlphabetical:c]) return YES;
	}
	if (charType & NUMERICAL) {
		if (isdigit(c)) return YES;
	}
	if (charType & NON_BREAKING_PUNCT) {
		if (c == '\'' || c == '-') return YES;
	}
	if (charType & BREAKING_PUNCT) {
		if (ispunct(c) && ![self charAt:pos hasType:XML_PUNCT] && [self charAt:pos hasType:NON_BREAKING_PUNCT]) return YES;
	}
	if (charType & XML_NAME_START) {
		if (isalpha(c) || c == ':' || c == '_') return YES;
	}
	if (charType & XML_NAME) {
		if ([self charAt:pos hasType:XML_NAME_START] || isdigit(c) || c == '.' || c == '-') return YES;
	}
	if (charType & XML_QUOTE) {
		if (c == '\'' || c == '"') return YES;
	}
	
	return NO;
}

-(BOOL)currentCharHasType:(enum LTWXMLParserCharType)charType {
	return [self charAt:current hasType:charType];
}

-(void)countAndSkipCurrentCharacter {
    if ([textTagNames containsObject:[tagStack lastObject]]) {
        textChars++;
        //fprintf(stderr, "%C", [self charAt:current]);
    }
    current++;
}

-(void)addTagToStack:(NSString*)tagName {
    [tagStack addObject:tagName];
}

-(void)removeTagFromStack {
    if ([tagStack count] > 0) [tagStack removeLastObject];
}

-(void)putXMLAttributesInExtraInfo:(NSMutableDictionary*)extraInfo encoded:(BOOL)isEncoded {
	while (![self currentCharHasType:(XML_PUNCT | END_OF_STRING)]) {
		
		if ([self charAt:current] == '&' && [self charAt:current+1] == 'g' && [self charAt:current+2] == 't' && [self charAt:current+3] == ';') {
			current += 3;
            [self countAndSkipCurrentCharacter];
			break;
		}
		
		while (isspace([self charAt:current]) || [self charAt:current] == '/') if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
		
		while (![self currentCharHasType:(XML_PUNCT | XML_NAME_START | END_OF_STRING)]) if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
		
		if ([self currentCharHasType:XML_NAME_START]) {
			NSInteger start = current;
			if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
			while ([self currentCharHasType:XML_NAME]) if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
			
			NSString *attributeName = [self substringWithRange:NSMakeRange(start, current-start)];
			
			while (![self currentCharHasType:(XML_QUOTE | XML_PUNCT | END_OF_STRING)] && [self charAt:current] != '&') if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
			if ([self currentCharHasType:(XML_PUNCT | END_OF_STRING)] && [self charAt:current] != '&') return;
			
			unichar quote = [self charAt:current];
			if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
			
			if (quote == '&') {
				while ([self charAt:current] != ';' && [self charAt:current] != '\0') current++;
				current++;
			}
			
			start = current;
			while ([self charAt:current] != quote && [self charAt:current] != '\0') if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
			
			NSString *attributeValue = [self substringWithRange:NSMakeRange(start, current-start)];
			
			[extraInfo setObject:attributeValue forKey:[@"attribute" stringByAppendingString:[attributeName capitalizedString]]];
			
			if (quote == '&') {
				while ([self charAt:current] != ';' && [self charAt:current] != '\0') current++;
			}
			
			if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
		}
	}
}

-(void)skipOverXMLComment {
	if ([self charAt:current+1] == '-' && [self charAt:current+2] == '-') {
		// <!-- /// --> (XML Comment)
		while ([self charAt:current] != '\0') {
			if ([self charAt:current] == '-' && [self charAt:current+1] == '-') {
				if ([self charAt:current+2] == '>') {
					current = current+3;
					break;
				}
				if ([self charAt:current+2] == '&' && [self charAt:current+3] == 'g' && [self charAt:current+4] == 't' && [self charAt:current+5] == ';') {
					current = current+6;
					break;
				}
			}
			current++;
		}
	}else if ([self charAt:current+1] == '[' && [self charAt:current+2] == 'C') {
		// Something like <![CDATA[<tag>...</tag>]]>
		while ([self charAt:current] != '\0') {
			if ([self charAt:current] == ']' && [self charAt:current+1] == ']') {
				if ([self charAt:current+2] == '>') {
					current = current+3;
					break;
				}
				if ([self charAt:current+2] == '&' && [self charAt:current+3] == 'g' && [self charAt:current+4] == 't' && [self charAt:current+5] == ';') {
					current = current+6;
					break;
				}
			}
			current++;
		}
	}else{
		// Maybe <!DOCTYPE ...>
		while ([self charAt:current] != '\0' && [self charAt:current] != '>') {
			current++;
		}
		current++;
	}
}

-(void)skipOverXMLDirective {
	current++;
	if ([self charAt:current] != '\0') {
		while ([self charAt:current+1] != '\0') {
			if ([self charAt:current] != '?') {
				if ([self charAt:current+1] == '>') {
					current = current+2;
					break;
				}
				if ([self charAt:current+1] == '&' && [self charAt:current+2] == 'g' && [self charAt:current+3] == 't' && [self charAt:current+4] == ';') {
					current = current+5;
					break;
				}
			}
			current++;
		}
	}
}

-(NSRange)getXMLTokenWithExtraInfo:(NSMutableDictionary*)extraInfo tokenType:(LTWTokenType*)tokenType {
	BOOL isXMLStart;
    BOOL isEncoded = NO;
    
    NSUInteger realTagStart = current; // the position of the < or &
	
	if ([self charAt:current] == '&') {
		NSUInteger start = current;
		while ([self charAt:current] != ';') current++;
        [self countAndSkipCurrentCharacter]; // just count this as one character.
		
		// If we see an entity other than "&lt;", just skip over it.
		if ([@"&lt;" isEqual:[self substringWithRange:NSMakeRange(start, current-start)]]) {
			isXMLStart = YES;
            isEncoded = YES;
		}else{
			isXMLStart = NO;
		}
	}else if ([self charAt:current] == '<') {
		current++;
		isXMLStart = YES;
	}else{
		// This shouldn't happen in valid XML. If it does, the best we can do is skip over the offending character and let the caller try again.
        [self countAndSkipCurrentCharacter];
		isXMLStart = NO;
	}
	
	if (!isXMLStart) return NSMakeRange(NSNotFound, 0);
	
	[extraInfo setObject:[NSNumber numberWithBool:YES] forKey:@"isXML"];
	
	if ([self charAt:current] == '?') {
		[self skipOverXMLDirective];
		return NSMakeRange(NSNotFound, 0);
	}else if ([self charAt:current] == '!') {
		[self skipOverXMLComment];
		return NSMakeRange(NSNotFound, 0);
	}
    
	if ([self charAt:current] == '/') {
		[extraInfo setObject:[NSNumber numberWithBool:YES] forKey:@"isEndTag"];
		if (!isEncoded) current++; else [self countAndSkipCurrentCharacter]; // skip over '/' if this is an end tag.
		*tokenType |= XML_END_TAG;
	}else{
		*tokenType |= XML_START_TAG;	
	}
    
    if (!isEncoded && (*tokenType & XML_END_TAG)) {
        [self removeTagFromStack];
    }
	
	if ([self currentCharHasType:XML_NAME_START]) {
		NSUInteger start = current;
		
		if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
		while ([self currentCharHasType:XML_NAME]) if (!isEncoded) current++; else [self countAndSkipCurrentCharacter];
		
		NSRange xml_token = NSMakeRange(start, current-start);
		
		[self putXMLAttributesInExtraInfo:extraInfo encoded:isEncoded];
        
		// Skip over either ">" or "&gt;".
		if ([self charAt:current] == '&') {
			while ([self charAt:current] != ';') current++;
		}
		if (!isEncoded) current++; else [self countAndSkipCurrentCharacter]; // count as 1 char if encoded, 0 if not.
		
        if (!isEncoded && (*tokenType & XML_START_TAG)) {
            [self addTagToStack:[self substringWithRange:xml_token]];
        }
        
        [extraInfo setObject:[NSNumber numberWithInt:xml_token.location-realTagStart] forKey:@"tagStartOffset"];
        [extraInfo setObject:[NSNumber numberWithInt:(current - realTagStart)] forKey:@"tagLength"];
        
		return xml_token;
	}
	
	return NSMakeRange(NSNotFound, 0);	
}

-(NSRange)getNextTokenWithExtraInfo:(NSMutableDictionary *)extraInfo tokenType:(LTWTokenType*)tokenType {
	*tokenType = 0;
    
    [self ensureCharactersAvailableFromIndex:current];
	
	[extraInfo removeAllObjects];
	
	NSRange current_token = NSMakeRange(NSNotFound, 0);
	
	// Skip over unwanted initial characters.
	while (![self currentCharHasType:(XML_PUNCT | ALPHABETICAL | NUMERICAL | BREAKING_PUNCT | END_OF_STRING)]) [self countAndSkipCurrentCharacter];
    
    [extraInfo setObject:[NSNumber numberWithInt:textChars] forKey:@"INEXOffset"];
	
	if ([self currentCharHasType:ALPHABETICAL]) {
		NSUInteger start = current;
		while ([self currentCharHasType:(ALPHABETICAL | NON_BREAKING_PUNCT)]) [self countAndSkipCurrentCharacter];
		
		current_token.location = start;
		current_token.length = current - start;
	}else if ([self currentCharHasType:NUMERICAL]) {
		NSUInteger start = current;
		[self countAndSkipCurrentCharacter];
		while ([self currentCharHasType:(NUMERICAL | ALPHABETICAL | NON_BREAKING_PUNCT)]) [self countAndSkipCurrentCharacter];
		
		current_token.location = start;
		current_token.length = current - start;
	}else if ([self currentCharHasType:BREAKING_PUNCT]) { // initial non-breaking punctuation is skipped over, so we don't have to worry about it here.
		NSUInteger start = current;
        [self countAndSkipCurrentCharacter];
		
		current_token.location = start;
		current_token.length = current - start;
	}else if ([self currentCharHasType:END_OF_STRING]) {
		current_token.location = NSNotFound;
		current_token.length = 0;
	}else if ([self currentCharHasType:XML_PUNCT]) {
		// There are two characters that can start a tag: '<' starts an unencoded tag, and '&' starts an entity, which may be '&lt;' (or it may be something else, which we might want to return as a token later, but not for now.)
		// If [self getXMLToken] returns (NSNotFound, 0), it means there wasn't an interesting XML token at the current position, and whatever was there has been skipped over. In this case, we re-run getNextToken and return the result.
        
		current_token = [self getXMLTokenWithExtraInfo:extraInfo tokenType:tokenType];
		if (current_token.location == NSNotFound) current_token = [self getNextTokenWithExtraInfo:extraInfo tokenType:tokenType];
	}
	
	return current_token;
}

-(NSRange)getTokenUpToCharacter:(unichar)character {
    [self ensureCharactersAvailableFromIndex:current];
    
	NSUInteger start = current;
	while ([self charAt:current] != character && [self charAt:current] != '\0') [self countAndSkipCurrentCharacter];
	if ([self charAt:current] == '\0') return NSMakeRange(NSNotFound, 0);
	NSRange range = NSMakeRange(start, current-start);
    [self countAndSkipCurrentCharacter];
	return range;
}

-(NSRange)getNextTokenWithExtraInfo:(NSMutableDictionary*)extraInfo {
	LTWTokenType tokenType;
	return [self getNextTokenWithExtraInfo:extraInfo tokenType:&tokenType];
}

-(NSRange)getNextToken {
	return [self getNextTokenWithExtraInfo:nil];
}

-(NSRange)getNextTokenWithTokenType:(LTWTokenType*)tokenType {
	return [self getNextTokenWithExtraInfo:nil tokenType:tokenType];
}

@end
