//
//  main.m
//  LTWAssessmentTool
//
//  Created by David Alexander on 11/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>

#ifdef GTK_PLATFORM
#import <gtk/gtk.h>
#endif

#import "LTWGTKPlatform.h"

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
    
    //gtk_init(&argc, &argv);
    //[[LTWGTKPlatform sharedInstance] run];
    //return 0;

}

