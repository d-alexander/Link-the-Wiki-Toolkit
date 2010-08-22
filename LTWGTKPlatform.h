//
//  LTWGTKPlatform.h
//  LTWToolkit
//
//  Created by David Alexander on 17/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifdef GTK_PLATFORM


#import <Cocoa/Cocoa.h>
#import "LTWGUIPlatform.h"
#import "LTWAssessmentMode.h"
#import <gtk/gtk.h>


@interface LTWGTKPlatform : NSObject <LTWGUIPlatform> {
    id <LTWAssessmentMode> assessmentMode;
    GtkWidget *mainView;
    GtkBuilder *builder;
}

+(LTWGTKPlatform*)sharedInstance;
-(GtkWidget*)mainView;
-(GtkWidget*)componentWithRole:(NSString*)role inView:(GtkWidget*)view;
-(void)setRepresentedValue:(id)value forRole:(NSString*)role;
-(void)run;

@end

#endif