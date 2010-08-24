//
//  main.m
//  LTWAssessmentTool-Windows
//
//  Created by David Alexander on 15/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "LTWGUIMediator.h"

int main(int argc, char *argv[])
{

    //return NSApplicationMain(argc,  (const char **) argv);
    
    /*
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    gtk_init(&argc, &argv);
    [[LTWGTKPlatform sharedInstance] run];
    [pool drain];
     */
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [[LTWGUIMediator alloc] init];
    
    [pool drain];
    
    return 0;
}

