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
    
#ifdef GTK_PLATFORM
    LTWGUIViewAdapter *adapterToReturn = nil;
    
    GtkBuilder *builder = gtk_builder_new();
    gtk_builder_add_from_file(builder, [[GUIDefinitionPath stringByAppendingPathComponent:theFilePath] UTF8String], NULL);
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
    __block LTWGUIViewAdapter *adapterToReturn = nil;
    
    __block void (^traverseViewTree)(LTWGUIView*);
    traverseViewTree = ^(LTWGUIView *view) {
        NSString *role = [view role];
        LTWGUIViewAdapter *adapter = [LTWGUIViewAdapter adapterForView:view role:role delegate:theDelegate];
        if (role) {
            [roleDictionary setObject:adapter forKey:role];
            if ([role isEqual:theReturnedViewRole]) adapterToReturn = adapter;
        }
        NSArray *subviews = [view isKindOfClass:[NSView class]] ? [(NSView*)view subviews] : [view isKindOfClass:[NSWindow class]] ? [[(NSWindow*)view contentView] subviews] : nil;
        for (NSView *subview in subviews) {
            traverseViewTree(subview);
        }
    };
    
    NSArray *topLevelObjects = nil;
    NSNib *nib = [[NSNib alloc] initWithContentsOfURL:[NSURL URLWithString:[GUIDefinitionPath stringByAppendingPathComponent:theFilePath]]];
    [nib instantiateNibWithOwner:theDelegate topLevelObjects:&topLevelObjects];
    for (id object in topLevelObjects){
        if ([object isKindOfClass:[LTWGUIView class]]) traverseViewTree((LTWGUIView*)object);
    }
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
    if ([theView isKindOfClass:[NSWindow class]]) {
        adapter = [[LTWGUIWindowViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if ([theView isKindOfClass:[NSOutlineView class]]) {
        adapter = [[LTWGUITreeViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if ([theView isKindOfClass:[NSComboBox class]]) {
        adapter = [[LTWGUIComboBoxViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if ([theView isKindOfClass:[NSTextView class]]) {
        adapter = [[LTWGUITextViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else if ([theRole isEqual:@"assessmentModeContainer"]) {
        adapter = [[LTWGUIAssessmentContainerViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }else{
        adapter = [[LTWGUIGenericViewAdapter alloc] initWithView:theView role:theRole delegate:theDelegate];
    }
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
        representedObjects = [[LTWGUITreeBranch branchWithDictionary:[NSMutableDictionary dictionary] index:0] retain];
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
#else
    return [(NSView*)view frame].size;
#endif
}

-(LTWGUIView*)topLevelView {
#ifdef GTK_PLATFORM
    return gtk_widget_get_toplevel(view);
#else
    return nil;
#endif
}

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

    
#ifdef GTK_PLATFORM
    gtk_box_pack_end(GTK_BOX(view), assessmentMainView->view, TRUE, TRUE, 5);
    NSSize assessmentSize = [assessmentMainView size];
    
    LTWGUIView *mainWindow = [self topLevelView];
    if (!mainWindow) {
        NSLog(@"Cannot resize main window to accomodate assessment view's size, as main window cannot be found.");
        return;
    }
    
    NSInteger windowMaxX, windowMaxY;
    gtk_widget_translate_coordinates(view, mainWindow, (int)assessmentSize.width, (int)assessmentSize.height, &windowMaxX, &windowMaxY);
    gtk_window_resize(GTK_WINDOW(mainWindow), windowMaxX, windowMaxY);
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

@end

@implementation LTWGUIGenericTreeViewAdapter

#ifdef GTK_PLATFORM
void LTWGUIGenericTreeViewAdapter_toggled(GtkCellRendererToggle *cellRenderer, char *treePathString, LTWGUIGenericTreeViewAdapter *adapter);
#endif

-(id)objectAtIndexPath:(NSIndexPath*)indexPath {
    LTWGUITreeBranch *branch = representedObjects;
    for (NSUInteger position = 0; position < [indexPath length]; position++) {
        id object = [[branch dictionary] objectForKey:[NSNumber numberWithInt:[indexPath indexAtPosition:position]]];
        
        if (object) return object; // This SHOULD be the leaf.
        
        BOOL found = NO;
        for (id key in [branch dictionary]) {
            object = [[branch dictionary] objectForKey:key];
            
            if ([object isKindOfClass:[LTWGUITreeBranch class]] && [(LTWGUITreeBranch*)object index] == [indexPath indexAtPosition:position]) {
                branch = object;
                found = YES;
                break;
            }
        }
        
        if (!found) return nil;
    }
    
    return nil;
}



-(BOOL)useColumnPropertiesForObject:(id)object maxColumns:(NSUInteger)maxColumns {
    // Get the names of the properties that will be displayed in each of the table columns for this object. If these property-names aren't specified, just call the description method and use that as a single column.
    // If this is the first object, set up the table columns according to the given properties. Otherwise, make sure that the columns are the same for this one as for the first one, and if so, return YES in order to indicate that the object is ready to be inserted.
    NSArray *newColumnProperties;
    if ([object respondsToSelector:@selector(displayableProperties)]) {
        newColumnProperties = [object displayableProperties];
    }else{
        newColumnProperties = [NSArray arrayWithObject:@"description"];
    }
    
#ifdef GTK_PLATFORM
    if (!columnProperties) {
        
        columnProperties = [newColumnProperties retain];
        columnTypes = malloc([columnProperties count] * sizeof *columnTypes);
        usedColumnProperties = malloc([columnProperties count] * sizeof *usedColumnProperties);
        cellRenderers = [[NSMutableArray alloc] init];
        
        NSUInteger columnNumber = 0;
        for (NSString *property in columnProperties) {
            void *value;
            GType type;
            if ([LTWGUIGenericTreeViewAdapter translateValueForProperty:property ofObject:object intoObject:&value type:&type]) {
                char *cellAttribute;
                char *cellChangedSignalName;
                GtkCellRenderer *cellRenderer = [LTWGUIGenericTreeViewAdapter cellRendererForType:type attribute:&cellAttribute signal:&cellChangedSignalName];
                if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
                    gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(view), -1, [property UTF8String], cellRenderer, cellAttribute, columnNumber, NULL);
                }else{
                    gtk_cell_layout_pack_start(GTK_CELL_LAYOUT(view), cellRenderer, FALSE);
                    gtk_cell_layout_set_attributes(GTK_CELL_LAYOUT(view), cellRenderer, "text", 0, NULL);
                }
                
                [cellRenderers addObject:[NSValue valueWithPointer:cellRenderer]];
                
                // TEMP
                if (strcmp(cellChangedSignalName, "toggled") == 0) {
                    g_signal_connect(G_OBJECT(cellRenderer), cellChangedSignalName, G_CALLBACK(LTWGUIGenericTreeViewAdapter_toggled), self);
                }
                
                columnTypes[columnNumber] = type;
                usedColumnProperties[columnNumber] = [property retain];
                columnNumber++;
            }
            
            if (columnNumber == maxColumns) break;
        }
        
        numColumns = columnNumber;
        
    }else if (![columnProperties isEqual:newColumnProperties]) {
        return NO;
    }
    
    return YES;
#else
    return NO;
#endif
}

#ifdef GTK_PLATFORM
-(GtkTreeIter)iteratorForInsertingObject:(id)object {
    GtkTreeIter iterator;
    
    if ([object respondsToSelector:@selector(propertyHierarchy)]) {
        
        LTWGUITreeBranch *branch = representedObjects;
        GtkTreeIter parent;
        for (id property in [object propertyHierarchy]) {
            id propertyValue = [object valueForKey:property];
            
            LTWGUITreeBranch *nextBranch = [[branch dictionary] objectForKey:propertyValue];
            if (!nextBranch) {
                nextBranch = [[[LTWGUITreeBranch alloc] initWithDictionary:[NSMutableDictionary dictionary] index:[[branch dictionary] count]] autorelease];
                [[branch dictionary] setObject:nextBranch forKey:propertyValue];
                
                GtkTreeIter newBranchIterator;
                gtk_tree_store_append(store, &newBranchIterator, (branch == representedObjects ? NULL : &parent));
                gtk_tree_store_set(store, &newBranchIterator, 0, [[propertyValue description] UTF8String], -1);
            }
            
            GtkTreeIter newParent;
            gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(store), &newParent, (branch == representedObjects ? NULL : &parent), [nextBranch index]);
            parent = newParent;
            branch = nextBranch;
        }
        
        [[branch dictionary] setObject:object forKey:[NSNumber numberWithInt:[[branch dictionary] count]]];
        
        gtk_tree_store_append(store, &iterator, &parent);
    }else{
        [[representedObjects dictionary] setObject:object forKey:[NSNumber numberWithInt:[[representedObjects dictionary] count]]];
        
        gtk_tree_store_append(store, &iterator, NULL);
    }
    
    return iterator;
}

-(void)insertObject:(id)object {
    if ([self useColumnPropertiesForObject:object maxColumns:([self isKindOfClass:[LTWGUIComboBoxViewAdapter class]] ? 1 : UINT_MAX)]) {
        if (!store) {
            store = gtk_tree_store_newv(numColumns, columnTypes);
        }
        
        GtkTreeIter iterator = [self iteratorForInsertingObject:object];
        
        for (NSUInteger columnIndex = 0; columnIndex < numColumns; columnIndex++) {
            void *value;
            NSString *property = usedColumnProperties[columnIndex];
            [LTWGUIGenericTreeViewAdapter translateValueForProperty:property ofObject:object intoObject:&value type:NULL];
            gtk_tree_store_set(store, &iterator, columnIndex, value, -1);
        }
    }
}

+(BOOL)translateValueForProperty:(NSString*)property ofObject:(id)object intoObject:(void**)destination type:(GType*)type {
    id value = [object valueForKey:property];
    if ([value isKindOfClass:[NSString class]]) {
        if (destination) *destination = strdup([value UTF8String]);
        if (type) *type = G_TYPE_STRING;
        return YES;
    }else if ([value isKindOfClass:[NSValue class]] && strcmp([value objCType], @encode(BOOL)) == 0) {
        if (destination) {
            *destination = malloc(sizeof (BOOL));
            *(BOOL*)*destination = [value boolValue];
        }
        if (type) *type = G_TYPE_BOOLEAN;
        return YES;
    }else{
        if (destination) *destination = strdup([[value description] UTF8String]);
        if (type) *type = G_TYPE_STRING;
        return YES;
    }
    
    // NOTE: Since we fall back to using the object's description if all else fails, we actually don't need to return a BOOL here at all -- it will always succeed.
    return NO;
}

+(GtkCellRenderer*)cellRendererForType:(GType)type attribute:(char**)attribute signal:(char**)signal {
    if (type == G_TYPE_STRING) {
        *attribute = "text";
        *signal = "edited";
        return gtk_cell_renderer_text_new();
    }else if (type == G_TYPE_BOOLEAN) {
        *attribute = "active";
        *signal = "toggled";
        return gtk_cell_renderer_toggle_new();
    }
    
    return NULL;
}

-(void)handleToggleForCellRenderer:(GtkCellRendererToggle*)cellRenderer treePathString:(char*)treePathString {
    GtkTreeIter iterator;
    gtk_tree_model_get_iter(GTK_TREE_MODEL(store), &iterator, gtk_tree_path_new_from_string(treePathString));
    BOOL oldValue;
    NSUInteger columnIndex = [cellRenderers indexOfObject:[NSValue valueWithPointer:cellRenderer]];
    gtk_tree_model_get(GTK_TREE_MODEL(store), &iterator, columnIndex, &oldValue, -1);
    gtk_tree_model_get_iter(GTK_TREE_MODEL(store), &iterator, gtk_tree_path_new_from_string(treePathString));
    gtk_tree_store_set(store, &iterator, columnIndex, !oldValue, -1);
}

void LTWGUIGenericTreeViewAdapter_toggled(GtkCellRendererToggle *cellRenderer, char *treePathString, LTWGUIGenericTreeViewAdapter *adapter) {
    [adapter handleToggleForCellRenderer:cellRenderer treePathString:treePathString];
}
#endif

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
    
    // NOTE: This should be duplicated in the other views that support the CLEAR mutation.
    if (mutationType == CLEAR) {
        store = NULL;
        columnProperties = nil;
        [[representedObjects dictionary] removeAllObjects];
        storeConnected = NO;
        cellRenderers = nil;
        gtk_tree_view_set_model(GTK_TREE_VIEW(view), NULL);
        return;
    }
    
    
    if (!object) {
        NSLog(@"Trying to apply mutation on %@ with nil object, which is not yet implemented!", self);
        return;
    }
    
    [self insertObject:object];
    
    if (!signalConnected) {
        g_signal_connect(G_OBJECT(view), "cursor_changed", G_CALLBACK(LTWGUITreeViewAdapter_cursorChanged), self);
        signalConnected = YES;
    }
    if (!storeConnected) {
        gtk_tree_view_set_model(GTK_TREE_VIEW(view), GTK_TREE_MODEL(store));
        storeConnected = YES;
    }

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
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:gtk_tree_path_get_indices(path) length:gtk_tree_path_get_depth(path)];
        
        [adapter objectSelected:[adapter objectAtIndexPath:indexPath]];
        
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
    
    [self insertObject:object];
    
    if (!signalConnected) {
        g_signal_connect(G_OBJECT(view), "changed", G_CALLBACK(LTWGUIComboBoxViewAdapter_changed), self);
    }
    if (!storeConnected) {
        gtk_combo_box_set_model(GTK_COMBO_BOX(view), GTK_TREE_MODEL(store));
        storeConnected = YES;
    }

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

#ifdef GTK_PLATFORM

typedef struct {
    GtkTextTag *tag;
    GtkTextMark *start;
} HTMLConversionStackEntry;

void LTWGUITextViewAdapter_exposed(GtkTextView *textView, GdkEventExpose *event);

-(BOOL)getTag:(GtkTextTag**)tag forXMLTokenAtIndex:(NSUInteger)tokenIndex inTokens:(LTWTokens*)tokens usingBuffer:(GtkTextBuffer*)buffer {
    // NOTE: These comparisons should be made case-insensitive.
    NSString *tagName = [[tokens _text] substringWithRange:[tokens rangeOfTokenAtIndex:tokenIndex]];
    
    if ([tagName isEqual:@"h3"]) {
        *tag = gtk_text_buffer_create_tag(buffer, NULL, "scale", PANGO_SCALE_LARGE, NULL);
        GtkTextIter iter;
        gtk_text_buffer_get_end_iter(buffer, &iter);
        gtk_text_buffer_insert(buffer, &iter, "\n", 1);
        return YES;
    }else if ([tagName isEqual:@"p"]) {
        *tag = NULL;
        GtkTextIter iter;
        gtk_text_buffer_get_end_iter(buffer, &iter);
        gtk_text_buffer_insert(buffer, &iter, "\n", 1);
        return YES;
    }else if ([tagName isEqual:@"br"]) {
        GtkTextIter iter;
        gtk_text_buffer_get_end_iter(buffer, &iter);
        gtk_text_buffer_insert(buffer, &iter, "\n", 1);
        return NO;
    }
    
    *tag = NULL;
    return YES;
}

-(void)insertHTMLTokens:(LTWTokens*)tokens {
    NSMutableArray *stack = [NSMutableArray array];
    
    NSUInteger numTokens = [tokens count];
    NSString *tokensText = [tokens _text];
    
    tokenStartMarks = malloc(numTokens * sizeof **tokenStartMarks);
    tokenEndMarks = malloc(numTokens * sizeof **tokenEndMarks);
    
    for (NSUInteger tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
        tokenStartMarks[tokenIndex] = NULL;
        tokenEndMarks[tokenIndex] = NULL;
        
        BOOL isXML = NO;
        BOOL isEndTag = NO;
        for (LTWTokenTag *tag in [tokens tagsStartingAtTokenIndex:tokenIndex]) {
            if ([[tag tagName] isEqual:@"isXML"]) {
                isXML = YES;
            }else if ([[tag tagName] isEqual:@"isEndTag"]) {
                isEndTag = YES;
            }
        }
        if (isEndTag) {
            // The corresponding start-tag should be at the top of the stack.
            if ([stack count] == 0) {
                NSLog(@"Stack empty while inserting HTML tokens into GTK text buffer!");
                continue;
            }
            HTMLConversionStackEntry *entry = [[stack lastObject] pointerValue];
            [stack removeLastObject];
            
            if (entry->tag) { // entry->tag is NULL if the corresponding XML tag has no effect on the text.
                GtkTextIter start, end;
                gtk_text_buffer_get_iter_at_mark(textBuffer, &start, entry->start);
                gtk_text_buffer_get_end_iter(textBuffer, &end);
                gtk_text_buffer_apply_tag(textBuffer, entry->tag, &start, &end);
            }
        }else if (isXML) { // start tag
            // NOTE: This is messy. The getTag:forXMLTokenAtIndex:inTokens:usingBuffer:method determines what the GtkTextTag should be for a given XML start tag, but sometimes there shouldn't be a tag, and sometimes we shouldn't even add an HTMLConversionStackEntry because the XML tag won't have a corresponding end-tag.
            // So, we return the GtkTextTag itself through a pointer (which may be NULL) and the return value specifies whether to add an entry to the stack at all.
            // It is possible for an XML tag not to result in an entry being created, despite having an effect on the buffer (e.g. <br> inserts a newline). Therefore, we also pass the buffer itself.
            GtkTextTag *tag = NULL;
            BOOL addEntry = [self getTag:&tag forXMLTokenAtIndex:tokenIndex inTokens:tokens usingBuffer:textBuffer];
            
            if (addEntry) {
                HTMLConversionStackEntry *entry = malloc(sizeof *entry);
                
                // NOTE: Should probably reuse tags when we want to create identical text properties more than once.
                entry->tag = tag;
                
                // Would it be better to create two marks -- start and end -- with left and right gravity respectively, and then insert the text "between" the marks? Would this be more efficient?
                entry->start = gtk_text_mark_new(NULL, YES); // create mark with left gravity and no name
                GtkTextIter iter;
                gtk_text_buffer_get_end_iter(textBuffer, &iter);
                gtk_text_buffer_add_mark(textBuffer, entry->start, &iter);
                
                [stack addObject:[NSValue valueWithPointer:entry]];
            }
        }else{ // not XML
            tokenStartMarks[tokenIndex] = gtk_text_mark_new(NULL, YES);
            tokenEndMarks[tokenIndex] = gtk_text_mark_new(NULL, YES);
            
            GtkTextIter iter;
            gtk_text_buffer_get_end_iter(textBuffer, &iter);
            gtk_text_buffer_add_mark(textBuffer, tokenStartMarks[tokenIndex], &iter);
            gtk_text_buffer_insert(textBuffer, &iter, [[tokensText substringWithRange:[tokens rangeOfTokenAtIndex:tokenIndex]] UTF8String], -1);
            gtk_text_buffer_get_end_iter(textBuffer, &iter);
            gtk_text_buffer_add_mark(textBuffer, tokenEndMarks[tokenIndex], &iter);
            gtk_text_buffer_insert(textBuffer, &iter, " ", 1);
        }
    }
    
}
#endif

-(void)setUpView {
#ifdef GTK_PLATFORM
    textBuffer = gtk_text_buffer_new(NULL);
    gtk_text_view_set_buffer(GTK_TEXT_VIEW(view), textBuffer);
    //g_signal_connect(G_OBJECT(view), "expose_event", G_CALLBACK(LTWGUITextViewAdapter_exposed), NULL);
#else
    
#endif
}

-(void)applyMutationWithType:(LTWGUIViewMutationType)mutationType object:(id)object {
    if (![object isKindOfClass:[LTWTokens class]]) return;
#ifdef GTK_PLATFORM
    gtk_text_buffer_set_text(textBuffer, "", -1);
    
    // NOTE: Should turn this into a proper "deserializing" function.
    [self insertHTMLTokens:(LTWTokens*)object];
    
    // Note sure if this is necessary.
    gtk_text_view_set_buffer(GTK_TEXT_VIEW(view), textBuffer);
#else
    
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

#ifdef GTK_PLATFORM
void LTWGUITextViewAdapter_exposed(GtkTextView *textView, GdkEventExpose *event) {
    /*
    GtkWidget *widget = GTK_WIDGET(textView);
    GdkPixmap *pixmap = gdk_pixmap_new(widget->window, widget->allocation.width, widget->allocation.height, -1);
    
    // NOTE: We should really only be calling this when the overlays (or the widget dimensions) change!
    drawOverlaysForTextView(textView, pixmap, gdk_gc_new(pixmap));
    
    gdk_draw_pixmap(widget->window,
                    widget->style->fg_gc[GTK_WIDGET_STATE (widget)], // what is this style used for?
                    pixmap,
                    event->area.x, event->area.y,
                    event->area.x, event->area.y,
                    event->area.width, event->area.height);
     */
}
#endif

@end

#pragma mark -
#pragma mark Miscellaneous

@implementation LTWGUITreeBranch

-(id)initWithDictionary:(NSMutableDictionary*)theDictionary index:(NSUInteger)theIndex {
    if (self = [super init]) {
        dictionary = [theDictionary retain];
        index = theIndex;
    }
    return self;
}

+(id)branchWithDictionary:(NSMutableDictionary*)theDictionary index:(NSUInteger)theIndex {
    return [[[LTWGUITreeBranch alloc] initWithDictionary:theDictionary index:theIndex] autorelease];
}

@synthesize dictionary;
@synthesize index;

@end


@implementation NSIndexPath (BugFix)

-(BOOL)isEqual:(id)other {
    return [other isKindOfClass:[NSIndexPath class]] && [self compare:other] == NSOrderedSame;
}

@end

#ifndef GTK_PLATFORM
static NSMutableDictionary *viewRoles = nil;

@implementation NSResponder (Roles)

-(NSString*)role {
    if (!viewRoles) viewRoles = [[NSMutableDictionary alloc] init];
    return [viewRoles objectForKey:[NSValue valueWithNonretainedObject:self]];
}

-(void)setRole:(NSString*)role {
    if (!viewRoles) viewRoles = [[NSMutableDictionary alloc] init];
    [viewRoles setObject:role forKey:[NSValue valueWithNonretainedObject:self]];
}

@end
#endif