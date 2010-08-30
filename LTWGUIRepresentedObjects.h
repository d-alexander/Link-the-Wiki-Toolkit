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
}

// NOTE: The return value of this function should probably be able to be changed without subclassing. This would make it much easier to make assessment modes that display different information.
-(NSArray*)displayableProperties;
-(NSArray*)propertyHierarchy;

// NOTE: These properties are only writable to avoid having to write an initialisation method. I will probably make them (readonly) later.
@property (retain) LTWTokens *anchor;
@property (retain) LTWArticle *target;

@end

@interface LTWGUIArticle : NSObject {
    LTWArticle *article;
}

// NOTE: The return value of this function should probably be able to be changed without subclassing. This would make it much easier to make assessment modes that display different information.
-(NSArray*)displayableProperties;

-(NSArray*)links;

@property (retain) LTWArticle *article;
@property (readonly) NSString *title;
@property (readonly) NSString *url;

@end