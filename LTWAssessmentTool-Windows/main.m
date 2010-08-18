//
//  main.m
//  LTWAssessmentTool-Windows
//
//  Created by David Alexander on 15/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <gtk/gtk.h>
#import "LTWGTKPlatform.h"

int main(int argc, char *argv[])
{

    //return NSApplicationMain(argc,  (const char **) argv);
    
    gtk_init(&argc, &argv);
    [[LTWGTKPlatform sharedInstance] run];
    return 0;
}

