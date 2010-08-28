//
//  LTWGUIViewAdapter.m
//  LTWToolkit
//
//  Created by David Alexander on 24/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWGUIViewAdapter.h"
#import "LTWGUIRepresentedObjects.h"
#import "LTWGUIMediator.h"

@implementation LTWGUIViewAdapter

static NSMutableDictionary *roleDictionary = nil;
static NSString *GUIDefinitionPath = @"";

+(void)setGUIDefinitionPath:(NSString*)thePath {
    GUIDefinitionPath = [thePath retain];
}

+(LTWGUIViewAdapter*)loadViewsFromFile:(NSString*)theFilePath withDelegate:(id)theDelegate returningViewWithRole:(NSString*)theReturnedViewRole {
    
    if (!roleDictionary) roleDictionary = [[NSMutableDictionary alloc] init];
    
    LTWGUIViewAdapter *adapterToReturn = nil;
#ifdef GTK_PLATFORM
    GtkBuilder *builder = gtk_builder_new();
    gtk_builder_add_from_file(builder, [[GUIDefinitionPath stringByAppendingString:theFilePath] UTF8String], NULL);
    GSList *objects = gtk_builder_get_objects(builder);
    for (GSList *elem = objects; elem != NULL; elem = g_slist_next(elem)) {
        LTWGUIView *view = GTK_WIDGET(elem->data);
        NSString *role = [NSString stringWithUTF8String:gtk_buildable_get_name(GTK_BUILDABLE(view))];
        LTWGUIViewAdapter *adapter = [LTWGUIViewAdapter adapterForView:view role:role delegate:theDelegate];
        [roleDictionary setObject:adapter forKey:role];
        if ([role isEqual:theReturnedViewRole]) adapterToReturn = adapter;
    }
    g_slist_free(objects);
#else
    
#endif
    return adapterToReturn;
}

+(LTWGUIViewAdapter*)adapterForView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)theDelegate {
    LTWGUIViewAdapter *adapter = nil;
#ifdef GTK_PLATFORM
    if (GTK_IS_WINDOW(theView)) {
        adapter = [[LTWGUIWindowViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if (GTK_IS_TREE_VIEW(theView)) {
        adapter = [[LTWGUITreeViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if (GTK_IS_COMBO_BOX(theView)) {
        adapter = [[LTWGUIComboBoxViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if (GTK_IS_TEXT_VIEW(theView)) {
       adapter = [[LTWGUITextViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if ([theRole isEqual:@"assessmentModeContainer"] && GTK_IS_CONTAINER(theView)) {
        adapter = [[LTWGUIAssessmentContainerViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else{
        adapter = [[LTWGUIGenericViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }
#else
    
#endif
    return [adapter autorelease];
}

+(LTWGUIViewAdapter*)adapterWithRole:(NSString*)role {
    return roleDictionary ? [[[roleDictionary objectForKey:role] retain] autorelease] : nil;
}

-(id)initWithView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)theDelegate {
    if (self = [super init]) {
        role = [theRole retain];
        view = RETAIN_VIEW(theView);
        delegate = [theDelegate retain];
        nilSubstitute = nil;
        representedObjects = [[NSMutableDictionary alloc] init];
        nextIndexPath = [[NSIndexPath indexPathWithIndex:0] retain];
        [self setUpView];
    }
    return self;
}

-(void)setUpView {
    return;
}

-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object {
    return;
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

-(void)setNilSubstitute:(id)theSubstitute {
    nilSubstitute = [theSubstitute retain];
}

-(void)objectSelected:(id)object {
    [delegate objectSelected:object inViewWithRole:role];
}

-(NSSize)size {
#ifdef GTK_PLATFORM
    GtkRequisition size;
    gtk_widget_size_request(view, &size);
    return NSMakeSize(size.width, size.height);
#endif
}

-(LTWGUIView*)topLevelView {
#ifdef GTK_PLATFORM
    return gtk_widget_get_toplevel(view);
#endif
}

-(void)object:(id)object insertedAtIndexPath:(NSIndexPath*)indexPath {
    // NOTE: Once it is possible to add objects at arbitrary positions (rather than just at the end of the tree) this method will need to be modified.
    [representedObjects setObject:object forKey:indexPath];
    
    
    if ([indexPath indexAtPosition:0] >= [nextIndexPath indexAtPosition:0]) {
        //[nextIndexPath release];
        nextIndexPath = [[NSIndexPath alloc] initWithIndex:[indexPath indexAtPosition:0]+1];
    }
}

-(id)objectAtIndexPath:(NSIndexPath*)indexPath {
    return [representedObjects objectForKey:indexPath];
}

#ifdef GTK_PLATFORM
+(BOOL)translateValue:(id)value intoObject:(void**)destination type:(GType*)type {
    if ([value isKindOfClass:[NSString class]]) {
        if (destination) *destination = strdup([value UTF8String]);
        if (type) *type = G_TYPE_STRING;
        return YES;
    }
    
    return NO;
}

+(GtkCellRenderer*)cellRendererForType:(GType)type {
    if (type == G_TYPE_STRING) {
        return gtk_cell_renderer_text_new();
    }
    
    return NULL;
}
#endif

@end

#pragma mark -
#pragma mark View Adapters

@implementation LTWGUIGenericViewAdapter


@end

@implementation LTWGUIWindowViewAdapter

-(void)setUpView {
    if ([role isEqual:@"dummyWindow"]) return;
#ifdef GTK_PLATFORM
    gtk_widget_show_all(view);
#else
    
#endif
}

-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object {
    return;
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

@end

@implementation LTWGUIAssessmentContainerViewAdapter

-(void)setUpView {
#ifdef GTK_PLATFORM
    
#else
    
#endif
}

-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object {
    
    if (![object isKindOfClass:[LTWGUIAssessmentMode class]]) return;
    
    LTWGUIViewAdapter *assessmentMainView = [LTWGUIViewAdapter loadViewsFromFile:[(LTWGUIAssessmentMode*)object GUIDefinitionFilename] withDelegate:delegate returningViewWithRole:@"assessmentMainView"];
    gtk_widget_reparent(assessmentMainView->view, view);
    NSSize assessmentSize = [assessmentMainView size];
    
    LTWGUIView *mainWindow = [self topLevelView];
    if (!mainWindow) {
        NSLog(@"Cannot resize main window to accomodate assessment view's size, as main window cannot be found.");
        return;
    }
    
#ifdef GTK_PLATFORM
    NSInteger windowMaxX, windowMaxY;
    gtk_widget_translate_coordinates(view, mainWindow, (int)assessmentSize.width, (int)assessmentSize.height, &windowMaxX, &windowMaxY);
    gtk_window_resize(GTK_WINDOW(mainWindow), windowMaxX, windowMaxY);
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

@end

@implementation LTWGUITreeViewAdapter

#ifdef GTK_PLATFORM
void LTWGUITreeViewAdapter_cursorChanged(GtkTreeView *view, LTWGUITreeViewAdapter *adapter);
#endif

-(void)setUpView {
#ifdef GTK_PLATFORM
    store = NULL;
    columnProperties = nil;
#else
    
#endif
}

-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object {
#ifdef GTK_PLATFORM
    if (!object) {
        NSLog(@"Trying to apply mutation on %@ with nil object, which is not yet implemented!", self);
        return;
    }
    
    // Get the names of the properties that will be displayed in each of the table columns for this object. If these property-names aren't specified, just call the description method and use that as a single column.
    // If this is the first object, set up the table columns according to the given properties. Otherwise, make sure that the columns are the same for this one as for the first one, and if so, insert the object.
    NSArray *newColumnProperties;
    if ([object respondsToSelector:@selector(displayableProperties)]) {
        newColumnProperties = [object displayableProperties];
    }else{
        newColumnProperties = [NSArray arrayWithObject:@"description"];
    }
    
    if (!columnProperties) {
        columnProperties = [newColumnProperties retain];
        columnTypes = malloc([columnProperties count] * sizeof *columnTypes);
        usedColumnProperties = malloc([columnProperties count] * sizeof *usedColumnProperties);
        
        NSUInteger columnNumber = 0;
        for (NSString *property in columnProperties) {
            void *value;
            GType type;
            if ([LTWGUIViewAdapter translateValue:[object valueForKey:property] intoObject:&value type:&type]) {
                GtkCellRenderer *cellRenderer = [LTWGUIViewAdapter cellRendererForType:type];
                gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(view), -1, [property UTF8String], cellRenderer, "text", columnNumber, NULL);
                columnTypes[columnNumber] = type;
                usedColumnProperties[columnNumber] = [property retain];
                columnNumber++;
            }
        }
        
        numColumns = columnNumber;
        
        store = gtk_tree_store_newv(numColumns, columnTypes);
        gtk_tree_view_set_model(GTK_TREE_VIEW(view), GTK_TREE_MODEL(store));
        g_signal_connect(G_OBJECT(view), "cursor_changed", G_CALLBACK(LTWGUITreeViewAdapter_cursorChanged), self);
    }else if (![columnProperties isEqual:newColumnProperties]) {
        return;
    }
    
    // Now that we've made sure that the columns are sorted out, insert the new row into the table.
    GtkTreeIter iterator;
    gtk_tree_store_append(store, &iterator, NULL);
    
    for (NSUInteger columnIndex = 0; columnIndex < numColumns; columnIndex++) {
        void *value;
        NSString *property = usedColumnProperties[columnIndex];
        [LTWGUIViewAdapter translateValue:[object valueForKey:property] intoObject:&value type:NULL];
        gtk_tree_store_set(store, &iterator, columnIndex, value, -1);
    }
    
    [self object:object insertedAtIndexPath:nextIndexPath];
#else
    
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

#ifdef GTK_PLATFORM
void LTWGUITreeViewAdapter_cursorChanged(GtkTreeView *view, LTWGUITreeViewAdapter *adapter) {
    GtkTreeSelection *selection = gtk_tree_view_get_selection(view);
    GtkTreeIter iter;
    GtkTreeModel *model;
    
    if (gtk_tree_selection_get_selected(selection, &model, &iter)) {
        GtkTreePath *path = gtk_tree_model_get_path(model, &iter);
        NSUInteger selectedIndex = gtk_tree_path_get_indices(path)[0];
        
        [adapter objectSelected:[adapter objectAtIndexPath:[NSIndexPath indexPathWithIndex:selectedIndex]]];
        
        gtk_tree_path_free(path);
    }else{
        [adapter objectSelected:nil];
    }

}
#endif

@end

@implementation LTWGUIComboBoxViewAdapter

#ifdef GTK_PLATFORM
void LTWGUIComboBoxViewAdapter_changed(GtkComboBox *view, LTWGUIComboBoxViewAdapter *data);
#endif

-(void)setUpView {
#ifdef GTK_PLATFORM
    store = NULL;
#else
    
#endif
}

-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object {
#ifdef GTK_PLATFORM
    
    if (!object) {
        NSLog(@"Trying to apply mutation on %@ with nil object, which is not yet implemented!", self);
        return;
    }
    
    // Get the property-names of the object, as with LTWGUITreeViewAdapter, but here we'll only use the first property (which we always treat as a string) since we don't have "columns" to fill.
    NSArray *newColumnProperties;
    if ([object respondsToSelector:@selector(displayableProperties)]) {
        newColumnProperties = [object displayableProperties];
    }else{
        newColumnProperties = [NSArray arrayWithObject:@"description"];
    }
    
    if (!columnProperties) {
        columnProperties = [newColumnProperties retain];
        columnTypes = malloc([columnProperties count] * sizeof *columnTypes);
        usedColumnProperties = malloc([columnProperties count] * sizeof *usedColumnProperties);
        
        NSUInteger columnNumber = 0;
        for (NSString *property in columnProperties) {
            void *value;
            GType type;
            if ([LTWGUIViewAdapter translateValue:[object valueForKey:property] intoObject:&value type:&type] && type == G_TYPE_STRING) {
                
                GtkCellRenderer *cellRenderer = [LTWGUIViewAdapter cellRendererForType:type];
                gtk_cell_layout_pack_start(GTK_CELL_LAYOUT(view), cellRenderer, FALSE);
                gtk_cell_layout_set_attributes(GTK_CELL_LAYOUT(view), cellRenderer, "text", 0, NULL);
                columnTypes[columnNumber] = type;
                usedColumnProperties[columnNumber] = [property retain];
                columnNumber++;
                
                // Now that we've got one column, we're done.
                break;
            }
        }
        
        numColumns = columnNumber;
        
        store = gtk_tree_store_newv(numColumns, columnTypes);
        gtk_combo_box_set_model(GTK_COMBO_BOX(view), GTK_TREE_MODEL(store));
        g_signal_connect(G_OBJECT(view), "changed", G_CALLBACK(LTWGUIComboBoxViewAdapter_changed), self);
    }else if (![columnProperties isEqual:newColumnProperties]) {
        return;
    }
    
    // Now that we've made sure that the columns are sorted out, insert the new row into the table.
    GtkTreeIter iterator;
    gtk_tree_store_append(store, &iterator, NULL);
    
    for (NSUInteger columnIndex = 0; columnIndex < numColumns; columnIndex++) {
        void *value;
        NSString *property = usedColumnProperties[columnIndex];
        [LTWGUIViewAdapter translateValue:[object valueForKey:property] intoObject:&value type:NULL];
        gtk_tree_store_set(store, &iterator, columnIndex, value, -1);
    }
    
    [self object:object insertedAtIndexPath:nextIndexPath];
#else
    
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

#ifdef GTK_PLATFORM
void LTWGUIComboBoxViewAdapter_changed(GtkComboBox *view, LTWGUIComboBoxViewAdapter *adapter) {
    NSInteger selectedIndex = gtk_combo_box_get_active(view);
    [adapter objectSelected:[adapter objectAtIndexPath:[NSIndexPath indexPathWithIndex:selectedIndex]]];
}
#endif

@end

@implementation LTWGUITextViewAdapter

-(void)setUpView {
#ifdef GTK_PLATFORM
    
#else
    
#endif
}

-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object {
    return;
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

@end

@interface NSIndexPath (BugFix)

@end

@implementation NSIndexPath (BugFix)

-(BOOL)isEqual:(id)other {
    return [other isKindOfClass:[NSIndexPath class]] && [self compare:other] == NSOrderedSame;
}

@end