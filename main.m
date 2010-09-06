//
//  main.m
//  LTWToolkit
//
//  Created by David Alexander on 26/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTWGUIMediator.h"

int main(int argc, char *argv[])
{
    //return NSApplicationMain(argc,  (const char **) argv);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[LTWGUIMediator alloc] init];
    [pool drain];
}
