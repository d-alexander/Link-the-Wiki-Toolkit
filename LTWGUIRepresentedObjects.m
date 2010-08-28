//
//  LTWGUIRepresentedObjects.m
//  LTWToolkit
//
//  Created by David Alexander on 25/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIRepresentedObjects.h"

@implementation LTWGUILink

@synthesize anchor;
@synthesize target;

-(NSArray*)displayableProperties {
    return [NSArray arrayWithObjects:@"anchor", @"target", nil];
}



@end

@implementation LTWGUIArticle

@synthesize article;

-(NSArray*)displayableProperties {
    return [NSArray arrayWithObjects:@"title", @"url", nil];
}

-(NSString*)title {
    return @"placeholder title";
}

-(NSString*)url {
    return [article URL];
}



@end