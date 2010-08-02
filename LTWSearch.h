//
//  LTWSearch.h
//  LTWToolkit
//
//  Created by David Alexander on 2/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LTWTokens.h"
#import "LTWTokenProcessor.h"

@interface LTWSearch : NSObject {
    LTWTokens *tokens; // Is this an appropriate way to store a tag-search?
    LTWTokenProcessor *requester;
}

-(id)initWithTokens:(LTWTokens*)theTokens;
-(id)initWithString:(NSString*)theString;

@end
