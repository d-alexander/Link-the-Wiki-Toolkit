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

@interface LTWGUIArticle : NSObject {
    LTWArticle *article;
    BOOL isRelevant;
    LTWTokenTag *relevanceTag;
}

-(NSArray*)links;

@property (retain) LTWArticle *article;
@property (readonly) NSString *title;
@property (readonly) NSString *url;
@property BOOL isRelevant;

@end

@interface LTWGUIAnchor : NSObject {
    LTWTokens *tokens;
    BOOL isRelevant;
    LTWTokenTag *relevanceTag;
}

@property (retain) LTWTokens *tokens;
@property BOOL isRelevant;

@end

@interface LTWGUILink : NSObject {
    LTWGUIAnchor *anchor;
    LTWGUIArticle *target;
    BOOL isRelevant;
    LTWTokenTag *relevanceTag;
}

// NOTE: These properties are only writable to avoid having to write an initialisation method. I will probably make them (readonly) later.
@property (retain) LTWGUIAnchor *anchor;
@property (retain) LTWGUIArticle *target;
@property (nonatomic) BOOL isRelevant;

@end

@interface LTWGUILink (Additions) 
@end

@interface LTWGUIDatabaseFile : NSObject {
    NSString *filename;
    NSString *filePath;
}

@property (retain) NSString *filename;
@property (retain) NSString *filePath;

@end