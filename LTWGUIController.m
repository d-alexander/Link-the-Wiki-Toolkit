//
//  LTWGUIController.m
//  LTWToolkit
//
//  Created by David Alexander on 24/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIController.h"
#import "LTWGUIMediator.h"
#import "LTWArticle.h"
#import "LTWGUIRepresentedObjects.h"
#import "LTWGUIViewAdapter.h"

@implementation LTWGUIController

-(void)GUIDidLoadWithContext:(id)context {
    [(LTWGUIGenericTreeViewAdapter*)[context viewWithRole:@"assessmentModeSelector"] setDisplayProperties:[NSArray arrayWithObjects:@"description",nil] hierarchyProperties:[NSArray array] withClasses:[NSArray arrayWithObjects:[LTWGUIAssessmentMode class],nil]];
    [(LTWGUIGenericTreeViewAdapter*)[context viewWithRole:@"assessmentFileSelector"] setDisplayProperties:[NSArray arrayWithObjects:@"filename",nil] hierarchyProperties:[NSArray array] withClasses:[NSArray arrayWithObjects:[LTWGUIDatabaseFile class],nil]];
}

-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role context:(id)context {
    if ([role isEqual:@"assessmentModeSelector"]) {
        [context setAssessmentMode:selectedObject];
    }else if ([role isEqual:@"assessmentFileSelector"]) {
        
        [context loadAssessmentFile:selectedObject]; 
        
    }else if ([role isEqual:@"sourceArticleLinks"]) {
        // NOTE: This may not work properly with the current hierarchical tree-viewing setup. Check it.
        if ([selectedObject isKindOfClass:[LTWGUIArticle class]]) {
            // A target has been selected from the link-tree view, so load its article into the targetArticleBody view.
            [context addObject:[[selectedObject article] tokensForField:@"body"] toViewWithRole:@"targetArticleBody"];
        }else if ([selectedObject isKindOfClass:[LTWGUIAnchor class]]) {
            // Highlight and scroll to the selected anchor.
            [(LTWGUITextViewAdapter*)[context viewWithRole:@"sourceArticleBody"] selectTokens:[selectedObject tokens]];
        }else if ([selectedObject isKindOfClass:[LTWGUILink class]]) {
            // Highlight and scroll to the selected anchor AND show the target.
            [(LTWGUITextViewAdapter*)[context viewWithRole:@"sourceArticleBody"] selectTokens:[[selectedObject anchor] tokens]];
            [context addObject:[[[selectedObject target] article] tokensForField:@"body"] toViewWithRole:@"targetArticleBody"];
        }
    }else if ([role isEqual:@"undoButton"]) {
        [LTWGUICommand undoLastCommand];
    }else if ([role isEqual:@"redoButton"]) {
        [LTWGUICommand redoNextCommand];
    }else if ([role isEqual:@"uploadButton"]) {
        [context uploadCurrentAssessmentFile];
    }else if ([role isEqual:@"selectAssessmentFileButton"]) {
        [(LTWGUIWindowViewAdapter*)[context viewWithRole:@"assessmentFileSelectorDialog"] displayModallyAbove:(LTWGUIWindowViewAdapter*)[context viewWithRole:@"mainWindow"]];
    }else if ([role isEqual:@"assessmentFileSelectorDialogCloseButton"]) {
        [(LTWGUIWindowViewAdapter*)[context viewWithRole:@"assessmentFileSelectorDialog"] hide];
    }else if ([role isEqual:@"revealAssessmentFilesButton"]) {
        [NSThread detachNewThreadSelector:@selector(revealCurrentAssessmentFile) toTarget:context withObject:nil];
    }else if ([role isEqual:@"reportBugButton"]) {
        [(LTWGUIWindowViewAdapter*)[context viewWithRole:@"reportBugDialog"] displayModallyAbove:(LTWGUIWindowViewAdapter*)[context viewWithRole:@"mainWindow"]];
    }else if ([role isEqual:@"reportBugDialogCloseButton"]) {
        [(LTWGUIWindowViewAdapter*)[context viewWithRole:@"reportBugDialog"] hide];
    }else if ([role isEqual:@"submitBugReportButton"]) {
        [context submitBugReport];
    }
}

@end

@implementation LTWGUIAssessmentMode

-(NSString*)GUIDefinitionFilename {
    return nil;
}

-(void)assessmentModeDidLoadWithContext:(id)context {
    
}

+(NSArray*)assessmentModes {
    return [NSArray arrayWithObjects:[[LTWGUISimpleAssessmentMode alloc] init], [[LTWGUISortedAssessmentMode alloc] init], [[LTWGUIAnchorTargetAssessmentMode alloc] init], [[LTWGUITargetAnchorAssessmentMode alloc] init], nil];
}

@end

#pragma mark -
#pragma mark Assessment Modes

@implementation LTWGUISimpleAssessmentMode

-(NSString*)GUIDefinitionFilename {
#ifdef GTK_PLATFORM
    return @"SimpleAssessmentMode.glade";
#else
    return @"LTWSimpleAssessmentMode.nib";
#endif
}

-(NSString*)description {
    return @"Simple Assessment Mode";
}

-(void)assessmentModeDidLoadWithContext:(id)context {
    [(LTWGUIGenericTreeViewAdapter*)[context viewWithRole:@"sourceArticleLinks"] setDisplayProperties:[NSArray arrayWithObjects:@"anchor", @"target", @"isRelevant",nil] hierarchyProperties:[NSArray array]  withClasses:[NSArray arrayWithObjects:[LTWGUILink class], [LTWGUIArticle class],nil]];
}

@end

@implementation LTWGUISortedAssessmentMode

-(NSString*)GUIDefinitionFilename {
#ifdef GTK_PLATFORM
    return @"SimpleAssessmentMode.glade";
#else
    return @"LTWSimpleAssessmentMode.nib";
#endif
}

-(NSString*)description {
    return @"Sorted Assessment Mode";
}

-(void)assessmentModeDidLoadWithContext:(id)context {
    [(LTWGUIGenericTreeViewAdapter*)[context viewWithRole:@"sourceArticleLinks"] setDisplayProperties:[NSArray arrayWithObjects:@"anchor", @"target", @"isRelevant",@"anchorIsRelevant", @"targetIsRelevant",nil] hierarchyProperties:[NSArray array]  withClasses:[NSArray arrayWithObjects:[LTWGUILink class],nil]];
}

@end

@implementation LTWGUIAnchorTargetAssessmentMode

-(NSString*)GUIDefinitionFilename {
#ifdef GTK_PLATFORM
    return @"SimpleAssessmentMode.glade";
#else
    return @"LTWSimpleAssessmentMode.nib";
#endif
}

-(NSString*)description {
    return @"Anchor \u2192 Target Assessment Mode";
}

-(void)assessmentModeDidLoadWithContext:(id)context {
    [(LTWGUIGenericTreeViewAdapter*)[context viewWithRole:@"sourceArticleLinks"] setDisplayProperties:[NSArray arrayWithObjects:@"anchor", @"target", @"isRelevant",nil] hierarchyProperties:[NSArray array]  withClasses:[NSArray arrayWithObjects:[LTWGUILink class], [LTWGUIArticle class],nil]];
}

@end

@implementation LTWGUITargetAnchorAssessmentMode

-(NSString*)GUIDefinitionFilename {
#ifdef GTK_PLATFORM
    return @"SimpleAssessmentMode.glade";
#else
    return @"LTWSimpleAssessmentMode.nib";
#endif
}

-(NSString*)description {
    return @"Target \u2192 Anchor Assessment Mode";
}

-(void)assessmentModeDidLoadWithContext:(id)context {
    [(LTWGUIGenericTreeViewAdapter*)[context viewWithRole:@"sourceArticleLinks"] setDisplayProperties:[NSArray arrayWithObjects:@"anchor", @"target", @"isRelevant",nil] hierarchyProperties:[NSArray arrayWithObject:@"target"]  withClasses:[NSArray arrayWithObjects:[LTWGUILink class], [LTWGUIArticle class],nil]];
}

@end