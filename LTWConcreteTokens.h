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
	NSMutableArray *tokenExtraInfos; // NOTE: Currently, these extraInfo dictionaries are used to get the attributes for a given token. It would be really nice if we could find a nicer way of doing this, since the current approach introduces a lot of coupling. Also, it's not going to be a very efficient way to store large numbers of tokens!
	NSMutableDictionary *tokenTags; // maps NSRanges of token indices onto NSArrays of LTWTokenTags.
    
    LTWDatabase *database;
    NSUInteger databaseID;
    BOOL inDatabase;
    BOOL inMemory;
    
    NSMutableArray *allSubTokens; // This is supposed to store all LTWConcreteSubTokens instances that currently have this LTWConcreteTokens instance as their superTokens. Before saving ourself to the database, we tell all our subtokens to "become independent" of us, which means that they create their own LTWConcreteTokens instance which holds only the tokens they need, and use it as their superTokens. (NOTE: I'm not sure what we should do if *that* instance needs to be saved to the database!) Ideally, we'd like to be able to tell them later (once we're back in memory) to re-parent themselves to us.
}

-(void)loadFromDatabase;
-(void)saveToDatabase;

@end
