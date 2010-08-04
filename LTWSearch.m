//
//  LTWSearch.m
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWSearch.h"

@implementation LTWSearch

+(NSArray*)parsePythonSearchArray:(PyObject*)object requester:(id <LTWSearchRequester>)theRequester {
    if (!PySequence_Check(object)) return [NSArray array];
    
    NSUInteger sequenceLength = PySequence_Length(object);
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:sequenceLength];
    
    for (NSUInteger i=0; i<sequenceLength; i++) {
        PyObject *item = PySequence_GetItem(object, i);
        
        LTWSearch *search = [[LTWSearch alloc] initWithPythonReturnTuple:item requester:theRequester];
        [array addObject:search];
    }
    
    return [array autorelease];
}

-(id)initWithPythonReturnTuple:(PyObject*)tuple requester:(id <LTWSearchRequester>)theRequester {
    if (self = [super init]) {
        requester = [theRequester retain];
        
        PyObject *pySearchTypeName, *pySearchSpec, *pyCorpusName, *pyArticleURL, *pyFieldName;
        PyObject *pySearchTokens, *pyLeftBoundingTokens, *pyRightBoundingTokens, *pySearchTagName, *pySearchTagValue;
        
        if (!PyArg_ParseTuple(tuple, "OOOOOOO", &pySearchTypeName, &pySearchSpec, &pyCorpusName, &pyArticleURL, &pyFieldName, &handlerMethod, &handlerMethodArgument)) goto invalid_search;
        
        NSString *searchTypeName;
        
        // NOTE: We're assuming here that if depythoniseObject:intoPointer: returns YES (i.e. it created an Objective-C object) that it created an object of the correct type. This should really be checked!
        if (![LTWPythonUtils depythoniseObject:pySearchTypeName intoPointer:(void**)&searchTypeName]) goto invalid_search;
        if (![LTWPythonUtils depythoniseObject:pyCorpusName intoPointer:(void**)&corpusName]) goto invalid_search;
        if (pyArticleURL == Py_None) {
            articleURL = nil;
        }else if (![LTWPythonUtils depythoniseObject:pyArticleURL intoPointer:(void**)&articleURL]) goto invalid_search;
        if (![LTWPythonUtils depythoniseObject:pyFieldName intoPointer:(void**)&fieldName]) goto invalid_search;
        
        // NOTE: We're currently not doing a case-insensitive compare, which we probably should be. (Although, ideally this string should be generated by a method called from Python rather than directly in the Python code.)
        searchType = [searchTypeName isEqual:@"entire_field"] ? ENTIRE_FIELD : [searchTypeName isEqual:@"bounded"] ? BOUNDED : [searchTypeName isEqual:@"tag"] ? TAG : INVALID;
        if (searchType == INVALID) goto invalid_search;
        
        if (searchType == BOUNDED) {
            if (!PyArg_ParseTuple(pySearchSpec, "OOO", &pyLeftBoundingTokens, &pySearchTokens, &pyRightBoundingTokens)) goto invalid_search;
            
            if (![LTWPythonUtils depythoniseObject:pyLeftBoundingTokens intoPointer:(void**)&leftBoundingTokens]) goto invalid_search;
            if (![LTWPythonUtils depythoniseObject:pySearchTokens intoPointer:(void**)&searchTokens]) goto invalid_search;
            if (![LTWPythonUtils depythoniseObject:pyRightBoundingTokens intoPointer:(void**)&rightBoundingTokens]) goto invalid_search;
        }else if (searchType == TAG) {
            if (!PyArg_ParseTuple(pySearchSpec, "OO", &pySearchTagName, &pySearchTagValue)) goto invalid_search;
            
            if (![LTWPythonUtils depythoniseObject:pySearchTagName intoPointer:(void**)&searchTagName]) goto invalid_search;
            
            if (pySearchTagValue == Py_None) {
                searchTagValue = nil;
            }else if (![LTWPythonUtils depythoniseObject:pySearchTagValue intoPointer:(void**)&searchTagValue]) goto invalid_search;
        }
    }
    
    return self;
    
invalid_search:
    searchType = INVALID;
    return self;
}

-(BOOL)tryOnTokenIndex:(NSUInteger)firstTokenIndex ofTokens:(LTWTokens*)theTokens fieldName:(NSString*)theFieldName corpusName:(NSString*)theCorpusName articleURL:(NSString*)theArticleURL newSearches:(NSMutableArray*)newSearches {
    
    // NOTE: Not all LTWTokens* instances will represent fields at all (although all of the ones we're given here should be).
    if (![fieldName isEqual:theFieldName]) return NO;
    if (![corpusName isEqual:theCorpusName]) return NO;
    if (articleURL && ![articleURL isEqual:theArticleURL]) return NO;
    
    NSUInteger lastTokenIndex = 0;
    
    // Block variables for the enumerateTagsWithBlock call that occurs later on.
    __block BOOL blockFoundApplicableTag = NO;
    __block NSUInteger blockLastTokenIndex = 0;
    
    // Used for BOUNDED searches.
    NSUInteger currentToken = firstTokenIndex;
    
    switch (searchType) {
        case INVALID:
            return NO;
            break; // just for good measure
        case ENTIRE_FIELD:
            if (firstTokenIndex == 0) {
                lastTokenIndex = [theTokens count];
            }else{
                return NO;
            }
            break;
        case BOUNDED:
            // Here, we're looking for an occurrence of leftBoundingTokens, then an occurrence of searchTokens (with no intervening occurrence of rightBoundingTokens) and finally an occurrence of rightBoundingTokens.
            // If leftBoundingTokens occurred, but rightBoundingTokens was either far away or nonexistent, this could be *very* inefficient, but fortunately we're typically going to use this kind of search for things like: "<h3>... something ...</h3>", and we would always expect the "</h3>" to exist.
            
            if (![theTokens matches:leftBoundingTokens fromIndex:firstTokenIndex]) return NO;
            
            currentToken += [leftBoundingTokens count];
            
            while (true) {
                if (currentToken >= [theTokens count]) return NO;
                
                if ([theTokens matches:rightBoundingTokens fromIndex:currentToken]) return NO;
                
                if ([theTokens matches:searchTokens fromIndex:currentToken]) break;
                
                currentToken++;
            }
            
            currentToken += [searchTokens count];
            
            while (true) {
                if (currentToken >= [theTokens count]) return NO;
                
                if ([theTokens matches:rightBoundingTokens fromIndex:currentToken]) {
                    lastTokenIndex = currentToken + [rightBoundingTokens count] - 1;
                    break;
                }
                
                currentToken++;
            }
            
            break;
        case TAG:
            // NOTE: This is terribly inefficient. The LTWTokens interface needs to be improved to fix this.
            [theTokens enumerateTagsWithBlock:^(NSRange tagTokenRange, LTWTokenTag *tag) {
                if (tagTokenRange.location == firstTokenIndex) {
                    blockFoundApplicableTag = YES;
                    blockLastTokenIndex = NSMaxRange(tagTokenRange)-1;
                }
            }];
            if (blockFoundApplicableTag) {
                lastTokenIndex = blockLastTokenIndex;
            }else{
                return NO;
            }
            break;
        default:
            return NO;
    }
    
    // If we haven't returned yet, we've got a match, and lastTokenIndex will have been set appropriately.
    
    if (requester) {
        LTWTokens *result = [theTokens tokensFromIndex:firstTokenIndex toIndex:lastTokenIndex propagateTags:YES];
        NSArray *searches = [requester handleSearchResult:result forSearch:self];
        if (searches) {
            [newSearches addObjectsFromArray:searches];
        }
    }
    return YES;
}

@end
