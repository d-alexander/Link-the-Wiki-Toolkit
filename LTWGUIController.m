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


@implementation LTWGUIController

-(void)objectSelected:(id)selectedObject inViewWithRole:(NSString*)role context:(id)context {
    if ([role isEqual:@"assessmentModeSelector"]) {
        [context setAssessmentMode:selectedObject];
    }else if ([role isEqual:@"articleSelector"]) {
        [context mutateViewWithRole:@"sourceArticleBody" mutationType:ADD object:[[(LTWGUIArticle*)selectedObject article] tokensForField:@"body"] caller:self];
        // NOTE: Should remove any old links before adding new ones!
        for (LTWGUILink *link in [(LTWGUIArticle*)selectedObject links]) {
            [context mutateViewWithRole:@"sourceArticleLinks" mutationType:ADD object:link caller:self];
        }
    }else if ([role isEqual:@"sourceArticleLinks"]) {
        // NOTE: This may not work properly with the current hierarchical tree-viewing setup. Check it.
        if ([selectedObject isKindOfClass:[LTWArticle class]]) {
            // A target has been selected from the link-tree view, so load its article into the targetArticleBody view.
            [context mutateViewWithRole:@"targetArticleBody" mutationType:ADD object:selectedObject caller:self];
        }else{
            // Something else (perhaps an anchor) has been selected. Leave it up to the specific assessment mode to decide what to do.
        }
    }
}

@end

@implementation LTWGUIAssessmentMode

-(NSString*)GUIDefinitionFilename {
    return nil;
}

-(BOOL)shouldMutateViewWithRole:(NSString*)role mutationType:(LTWGUIViewMutationType)mutationType object:(id)object {
    return YES;
}

@end

#pragma mark -
#pragma mark Assessment Modes

@implementation LTWGUISimpleAssessmentMode

-(NSString*)GUIDefinitionFilename {
#ifdef GTK_PLATFORM
    return @"SimpleAssessmentMode.glade";
#else
    return @"SimpleAssessmentMode.nib";
#endif
}

// TODO: Work out how to implement "highlighting", scrolling, etc using mutations.
-(BOOL)shouldMutateViewWithRole:(NSString*)role mutationType:(LTWGUIViewMutationType)mutationType object:(id)object {
    if ([role isEqual:@"sourceArticleLinks"]) {
        if ([object isKindOfClass:[LTWArticle class]]) {
            // Highlight all instances of this target.
        }else{
            // Highlight the particular anchor and scroll to it.
        }
    }
    
    return YES;
}

@end