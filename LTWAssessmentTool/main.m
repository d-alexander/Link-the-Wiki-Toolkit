//
//  main.m
//  LTWAssessmentTool
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTWGUIMediator.h"

int main(int argc, char *argv[])
{
    //return NSApplicationMain(argc,  (const char **) argv);
    printf("main\n");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[LTWGUIMediator alloc] initWithArguments:argv numArguments:argc];
    [pool drain];

}

