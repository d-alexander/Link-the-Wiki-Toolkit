//
//  LTWConcreteTokens.h
//  LTWToolkit
//
//  Created by David Alexander on 30/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LTWTokens.h"

#import "LTWDatabase.h"

@interface LTWConcreteTokens : LTWTokens {
	NSString *text;
	NSMutableArray *tokens;
    NSMutableArray *tagOccurrences; // Can't use NSPointerArray (Cocotron doesn't support it) so using NSArray of +[NSValue valueWithPointer:] instead.
    
    LTWDatabase *database;
    NSUInteger databaseID;
    BOOL inDatabase;
    BOOL inMemory;
}

-(void)loadFromDatabase;
-(void)saveToDatabase;

@end
