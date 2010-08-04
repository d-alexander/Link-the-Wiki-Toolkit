//
//  LTWSearch.h
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LTWTokens.h"

#import "LTWPythonUtils.h"

@class LTWSearch;
@protocol LTWSearchRequester <NSObject>

-(NSArray*)handleSearchResult:(LTWTokens*)result forSearch:(LTWSearch*)search;

@end

typedef enum {
    INVALID, // In case we can't make sense of a Python tuple we're given. (This search never matches anything.)
    ENTIRE_FIELD, // Searches are always restricted to a given field-name, but this search-type always matches the entire field.
    BOUNDED, // Matches a given sequence of tokens between (but not necessarily directly up against) two other specified sequences of tokens, e.g. "<h3>" and "</h3>".
    TAG // Matches a range of tokens that is tagged with a tag of the given name and value. (The value may be given as Py_None, meaning any value is allowed.)
} LTWSearchType;

@interface LTWSearch : NSObject {
    id <LTWSearchRequester> requester;
    
    LTWSearchType searchType;
    
    /*
     The fields below are filled in according to the type of search that is requested. Not all search-types use all fields. If a field is not used by the search-type of a particular LTWSearch instance, its value is undefined.
     
     It is important to consider this if creating any sort of lookup structure for LTWSearch instances!
     */
    
    // These fields are used by all search-types. The articleURL field may be nil.
    NSString *corpusName, *articleURL, *fieldName;
    PyObject *handlerMethod, *handlerMethodArgument;
    
    // Currently only used by BOUNDED searches, but will later be used by others.
    LTWTokens *searchTokens;
    
    // Used by BOUNDED searches.
    LTWTokens *leftBoundingTokens;
    LTWTokens *rightBoundingTokens;
    
    // Used by TAG searches.
    NSString *searchTagName;
    NSString *searchTagValue; // may be nil
}

+(NSArray*)parsePythonSearchArray:(PyObject*)object requester:(id <LTWSearchRequester>)theRequester;

-(id)initWithPythonReturnTuple:(PyObject*)tuple requester:(id <LTWSearchRequester>)theRequester; // This currently breaks LTWPythonUtils' encapsulation of the Python library, so it should probably be redesigned.

-(BOOL)tryOnTokenIndex:(NSUInteger)firstTokenIndex ofTokens:(LTWTokens*)theTokens fieldName:(NSString*)theFieldName corpusName:(NSString*)theCorpusName articleURL:(NSString*)theArticleURL newSearches:(NSMutableArray*)newSearches;

@end
