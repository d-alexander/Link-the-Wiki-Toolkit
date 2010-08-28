//
//  LTWGUIViewAdapter.h
//  LTWToolkit
//
//  Created by David Alexander on 24/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifdef GTK_PLATFORM
#import <Foundation/Foundation.h>
#import <gtk/gtk.h>
typedef GtkWidget LTWGUIView;
#define RETAIN_VIEW(view) (view)
#define RELEASE_VIEW(view) (view)
#else
#import <Cocoa/Cocoa.h>
typedef NSView LTWGUIView;
#define RETAIN_VIEW(view) ([view retain])
#define RELEASE_VIEW(view) ([view release])
#endif

typedef enum {
    ADD
} LTWGUIViewMutationType;


@interface LTWGUIViewAdapter : NSObject {
    NSString *role;
    LTWGUIView *view;
    id delegate;
    id nilSubstitute; // The object that gets displayed if a nil value is inserted into the view.
    NSMutableDictionary *representedObjects; // Maps NSIndexPaths to the Objective-C objects currently represented by them. NOTE: Large numbers of NSIndexPaths may need to be updated when an item is inserted in the middle of an object.
    NSIndexPath *nextIndexPath; // The NSIndexPath that the next object to be appended (i.e. inserted at the "bottom" of the list/tree will have).
}

+(void)setGUIDefinitionPath:(NSString*)thePath;
+(LTWGUIViewAdapter*)loadViewsFromFile:(NSString*)theFilePath withDelegate:(id)theDelegate returningViewWithRole:(NSString*)theReturnedViewRole;
+(LTWGUIViewAdapter*)adapterForView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)theDelegate;
+(LTWGUIViewAdapter*)adapterWithRole:(NSString*)role;

-(id)initWithView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)delegate;
-(void)setUpView;
-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object;
-(id <NSFastEnumeration>)objectsOfType:(Class*)type;
-(void)setNilSubstitute:(id)theSubstitute;
-(void)objectSelected:(id)object;
-(NSSize)size;
-(LTWGUIView*)topLevelView;

// "Private" utility methods.
-(void)object:(id)object insertedAtIndexPath:(NSIndexPath*)indexPath;
-(id)objectAtIndexPath:(NSIndexPath*)indexPath;
#ifdef GTK_PLATFORM
+(BOOL)translateValue:(id)value intoObject:(void**)destination type:(GType*)type;
+(GtkCellRenderer*)cellRendererForType:(GType)type;
#endif

@end

@interface LTWGUIGenericViewAdapter : LTWGUIViewAdapter {

}

@end

@interface LTWGUIWindowViewAdapter : LTWGUIViewAdapter {
    
}

@end

@interface LTWGUIAssessmentContainerViewAdapter : LTWGUIViewAdapter {
    
}

@end

@interface LTWGUITreeViewAdapter : LTWGUIViewAdapter {
#ifdef GTK_PLATFORM
    GtkTreeStore *store;
    NSArray *columnProperties;
    
    NSUInteger numColumns;
    GType *columnTypes;
    NSString **usedColumnProperties;
#else
    
#endif
}

@end

@interface LTWGUIComboBoxViewAdapter : LTWGUIViewAdapter {
#ifdef GTK_PLATFORM
    GtkTreeStore *store;
    NSArray *columnProperties;
    
    NSUInteger numColumns;
    GType *columnTypes;
    NSString **usedColumnProperties;
#else
    
#endif
}

@end

@interface LTWGUITextViewAdapter : LTWGUIViewAdapter {
#ifdef GTK_PLATFORM
    
#else
    
#endif
}

@end