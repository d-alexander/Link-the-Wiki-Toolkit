//
//  LTWGUIRepresentedObjects.h
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWTokens.h"
#import "LTWArticle.h"

@interface LTWGUILink : NSObject {
    LTWTokens *anchor;
    LTWArticle *target;
    BOOL isRelevant;
}

// NOTE: These properties are only writable to avoid having to write an initialisation method. I will probably make them (readonly) later.
@property (retain) LTWTokens *anchor;
@property (retain) LTWArticle *target;
@property BOOL isRelevant;

@end

@interface LTWGUIArticle : NSObject {
    LTWArticle *article;
}

-(NSArray*)links;

@property (retain) LTWArticle *article;
@property (readonly) NSString *title;
@property (readonly) NSString *url;

@end