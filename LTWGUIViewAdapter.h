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
typedef GType LTWGUIDataType;
#define RETAIN_VIEW(view) (view)
#define RELEASE_VIEW(view) (view)
#else
#import <Cocoa/Cocoa.h>
typedef NSObject LTWGUIView;
typedef Class LTWGUIDataType;
#define RETAIN_VIEW(view) ([view retain])
#define RELEASE_VIEW(view) ([view release])
#endif

@class LTWGUITreeBranch;

@interface LTWGUIViewAdapter : NSObject {
    NSString *role;
    LTWGUIView *view;
    id delegate;
    id nilSubstitute; // The object that gets displayed if a nil value is inserted into the view.
}

+(void)setGUIDefinitionPath:(NSString*)thePath;
+(LTWGUIViewAdapter*)loadViewsFromFile:(NSString*)theFilePath withDelegate:(id)theDelegate returningViewWithRole:(NSString*)theReturnedViewRole;
+(LTWGUIViewAdapter*)adapterForView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)theDelegate;
+(LTWGUIViewAdapter*)adapterWithRole:(NSString*)role;

-(id)initWithView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)delegate;
-(void)setUpView;
-(void)addObject:(id)object;
-(id <NSFastEnumeration>)objectsOfType:(Class*)type;
-(void)setNilSubstitute:(id)theSubstitute;
-(void)objectSelected:(id)object;
-(NSSize)size;
-(LTWGUIView*)topLevelView;


@end


#pragma mark -
#pragma mark View Adapters

@interface LTWGUIGenericViewAdapter : LTWGUIViewAdapter {

}

@end

@interface LTWGUIWindowViewAdapter : LTWGUIViewAdapter {
    
}

-(void)displayModallyAbove:(LTWGUIWindowViewAdapter*)parent;
-(void)hide;

@end

@interface LTWGUIStatusBarViewAdapter : LTWGUIViewAdapter {
    
}

@end

@interface LTWGUIAssessmentContainerViewAdapter : LTWGUIViewAdapter {
    
}

@end

@interface LTWGUIButtonViewAdapter : LTWGUIViewAdapter {
    
}

@end

@class LTWGUITreeModel;

@interface LTWGUIGenericTreeViewAdapter : LTWGUIViewAdapter {
    LTWGUITreeModel *model;
    
    // These are only here so that we can construct a new model when we want to get rid of an existing one.
    NSArray *storedDisplayProperties;
    NSArray *storedHierarchyProperties;
    NSArray *storedColumnClasses;
}

typedef struct {
    LTWGUIGenericTreeViewAdapter *adapter;
    NSUInteger columnIndex;
} LTWGUITreeViewAdapterColumn;

-(void)setDisplayProperties:(NSArray*)properties hierarchyProperties:(NSArray*)hierarchyProperties withClasses:(NSArray*)classes;
-(LTWGUITreeModel*)model;

@end

@interface LTWGUITreeViewAdapter : LTWGUIGenericTreeViewAdapter {
    
}

@end

@interface LTWGUIComboBoxViewAdapter : LTWGUIGenericTreeViewAdapter {
    
}

@end

@interface LTWGUITextViewAdapter : LTWGUIViewAdapter {
#ifdef GTK_PLATFORM
    GtkTextBuffer *textBuffer;
    GtkTextMark **tokenStartMarks, **tokenEndMarks;
#else
    
#endif
}

@end

#pragma mark -
#pragma mark Miscellaneous

#ifndef GTK_PLATFORM
@interface LTWGUIPathFormatter : NSFormatter {
    
}

@end
#endif

#ifdef GTK_PLATFORM
@interface LTWGUITreeModel : NSObject {
#else
@interface LTWGUITreeModel : NSObject <NSOutlineViewDataSource, NSComboBoxDataSource> {
#endif
#ifdef GTK_PLATFORM
    GtkTreeModel *model;
#else
    
#endif
    id delegate;
    NSMutableArray *levels;
    NSMutableArray *displayProperties;
    NSMutableArray *hierarchyProperties;
    NSMutableArray *columnTypes;
}

-(id)initWithDisplayProperties:(NSArray*)theDisplayProperties classes:(NSArray*)theClasses;
-(void)setHierarchyProperties:(NSArray*)hierarchyProperties;
-(NSArray*)columnTypes;
-(NSIndexPath*)addObject:(id)object;
-(void)moveObject:(id)object;
-(void)changeObject:(id)object newValue:(id)newValue forColumn:(NSUInteger)columnIndex;
-(void)removeObject:(id)object;
    
-(NSArray*)pathOfChildAtIndex:(NSUInteger)childIndex parentPath:(NSArray*)parentPath;

#ifdef GTK_PLATFORM
-(id)objectAtTreePath:(GtkTreePath*)treePath;
-(GtkTreeModel*)model;
-(GtkTreeIter)iteratorForIndexPath:(NSIndexPath*)indexPath;
#endif
    
@property (assign) id delegate;

@end

@interface NSIndexPath (BugFix)

@end

#ifndef GTK_PLATFORM
@interface NSResponder (Roles)

-(NSString*)role;
-(void)setRole:(NSString*)role;

@end
#endif