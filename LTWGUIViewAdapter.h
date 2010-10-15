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

#include "LTWTokens.h"

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
    
#ifdef GTK_PLATFORM
    GtkTreeModelSort *sortableModel;
#endif
    
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
-(void)expandNodes;

@end

@interface LTWGUITreeViewAdapter : LTWGUIGenericTreeViewAdapter {
    
}

@end

@interface LTWGUIComboBoxViewAdapter : LTWGUIGenericTreeViewAdapter {
    
}

@end

@class LTWGUITextModel;

@interface LTWGUITextViewAdapter : LTWGUIViewAdapter {
    NSMutableDictionary *models;
    LTWGUITextModel *model;
    LTWTokens *tokensBeingDisplayed;
}

-(NSString*)text;
-(void)selectTokens:(LTWTokens*)theTokens;
-(void)preCreateModelForObject:(id)object;

@end

#pragma mark -
#pragma mark Miscellaneous

#ifndef GTK_PLATFORM
@interface LTWGUIPathFormatter : NSFormatter {
    
}

@end
#endif

@interface LTWGUITextModel : NSObject {
    id object;
#ifdef GTK_PLATFORM
    GtkTextBuffer *textBuffer;
    GtkTextMark **tokenStartMarks, **tokenEndMarks;
#else
    NSMutableAttributedString *textStorage;
#endif
}

-(id)initWithObject:(id)object;
-(NSString*)text;
-(void)selectTokens:(LTWTokens*)tokens;

#ifdef GTK_PLATFORM
-(GtkTextBuffer*)buffer;
#else
-(NSMutableAttributedString*)buffer;
#endif

@end

#ifdef GTK_PLATFORM
@interface LTWGUITreeModel : NSObject {
#else
@interface LTWGUITreeModel : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate, NSComboBoxDataSource, NSComboBoxDelegate> {
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
    NSMutableArray *objects;
}

-(id)initWithDisplayProperties:(NSArray*)theDisplayProperties classes:(NSArray*)theClasses hierarchyProperties:(NSArray*)theHierarchyProperties;
-(void)addObjectsFromModel:(LTWGUITreeModel*)theModel;
-(NSArray*)columnTypes;
-(NSIndexPath*)addObject:(id)object;
-(void)moveObject:(id)object;
-(void)changeObject:(id)object newValue:(id)newValue forColumn:(NSUInteger)columnIndex;
-(void)removeObject:(id)object;
    
-(NSArray*)pathOfChildAtIndex:(NSUInteger)childIndex parentPath:(NSArray*)parentPath;
-(NSIndexPath*)rowReferenceForPath:(NSArray*)path;
-(id)valueIfExistsForProperty:(NSString*)propertyName ofObject:(id)object;

#ifdef GTK_PLATFORM
-(id)objectAtTreePath:(GtkTreePath*)treePath;
-(GtkTreeModel*)model;
-(GtkTreeIter)iteratorForIndexPath:(NSIndexPath*)indexPath;
-(void)setColumn:(NSUInteger)columnIndex indexPath:(NSIndexPath*)indexPath toValue:(id)value;
#endif
    
@property (assign) id delegate;

@end

@interface NSIndexPath (BugFix)

@end
    
@interface NSString (Presentation)
    
-(NSString*)presentableString;
    
@end

#ifndef GTK_PLATFORM
@interface NSResponder (Roles)

-(NSString*)role;
-(void)setRole:(NSString*)role;

@end
#endif