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
typedef NSResponder LTWGUIView;
#define RETAIN_VIEW(view) ([view retain])
#define RELEASE_VIEW(view) ([view release])
#endif

typedef enum {
    ADD
} LTWGUIViewMutationType;


@class LTWGUITreeBranch;

@interface LTWGUIViewAdapter : NSObject {
    NSString *role;
    LTWGUIView *view;
    id delegate;
    id nilSubstitute; // The object that gets displayed if a nil value is inserted into the view.
    LTWGUITreeBranch *representedObjects; // A tree of NSMutableDictionaries of objects that are represented by the view.
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


@end


#pragma mark -
#pragma mark View Adapters

@interface LTWGUIGenericViewAdapter : LTWGUIViewAdapter {

}

@end

@interface LTWGUIWindowViewAdapter : LTWGUIViewAdapter {
    
}

@end

@interface LTWGUIAssessmentContainerViewAdapter : LTWGUIViewAdapter {
    
}

@end

@interface LTWGUIGenericTreeViewAdapter : LTWGUIViewAdapter {
#ifdef GTK_PLATFORM
    GtkTreeStore *store;
    NSArray *columnProperties;
    NSUInteger numColumns;
    GType *columnTypes;
    NSString **usedColumnProperties;
#else
    
#endif
}

-(id)objectAtIndexPath:(NSIndexPath*)indexPath;
-(BOOL)useColumnPropertiesForObject:(id)object maxColumns:(NSUInteger)maxColumns;
#ifdef GTK_PLATFORM
-(void)insertObject:(id)object;
+(BOOL)translateValueForProperty:(NSString*)property ofObject:(id)object intoObject:(void**)destination type:(GType*)type;
+(GtkCellRenderer*)cellRendererForType:(GType)type attribute:(char**)attribute;
#endif
@end

@interface LTWGUITreeViewAdapter : LTWGUIGenericTreeViewAdapter {
#ifdef GTK_PLATFORM
    BOOL signalConnected;
    BOOL storeConnected;
#else
#endif
}

@end

@interface LTWGUIComboBoxViewAdapter : LTWGUIGenericTreeViewAdapter {
#ifdef GTK_PLATFORM
    BOOL signalConnected;
    BOOL storeConnected;
#else
#endif
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

@interface LTWGUITreeBranch : NSObject {
    NSMutableDictionary *dictionary;
    NSUInteger index;
}

-(id)initWithDictionary:(NSMutableDictionary*)theDictionary index:(NSUInteger)theIndex;
+(id)branchWithDictionary:(NSMutableDictionary*)theDictionary index:(NSUInteger)theIndex;

@property (readonly) NSMutableDictionary *dictionary;
@property (readonly) NSUInteger index;

@end

@interface NSIndexPath (BugFix)

@end

#ifndef GTK_PLATFORM
@interface NSResponder (Roles)

-(NSString*)role;
-(void)setRole:(NSString*)role;

@end
#endif