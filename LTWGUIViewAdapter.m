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

id delegateForLoadedViews = nil;

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
    delegateForLoadedViews = theDelegate;
    
    NSArray *topLevelObjects = nil;
    NSNib *nib = [[NSNib alloc] initWithContentsOfURL:[NSURL URLWithString:[GUIDefinitionPath stringByAppendingPathComponent:theFilePath]]];
    [nib instantiateNibWithOwner:theDelegate topLevelObjects:&topLevelObjects];

    LTWGUIViewAdapter *adapterToReturn = adapterToReturn = [roleDictionary objectForKey:theReturnedViewRole];
    
    delegateForLoadedViews = nil;
#endif
    return adapterToReturn;
}

+(LTWGUIViewAdapter*)adapterForView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)theDelegate {
    Class class = nil;
#ifdef GTK_PLATFORM
    if (GTK_IS_WINDOW(theView)) {
        class = [LTWGUIWindowViewAdapter class];
    }else if (GTK_IS_STATUSBAR(theView)) {
        class = [LTWGUIStatusBarViewAdapter class];
    }else if (GTK_IS_TREE_VIEW(theView)) {
        class = [LTWGUITreeViewAdapter class];
    }else if (GTK_IS_COMBO_BOX(theView)) {
        class = [LTWGUIComboBoxViewAdapter class];
    }else if (GTK_IS_TEXT_VIEW(theView)) {
       class = [LTWGUITextViewAdapter class];
    }else if (GTK_IS_BUTTON(theView)) {
        class = [LTWGUIButtonViewAdapter class];
    }else if ([theRole isEqual:@"assessmentModeContainer"] && GTK_IS_CONTAINER(theView)) {
        class = [LTWGUIAssessmentContainerViewAdapter class];
    }else{
        class = [LTWGUIGenericViewAdapter class];
    }
#else
    if ([theView isKindOfClass:[NSWindow class]]) {
        class = [LTWGUIWindowViewAdapter class];
    }else if ([theView isKindOfClass:[NSTextField class]] && [theRole isEqual:@"statusBar"]) {
        class = [LTWGUIStatusBarViewAdapter class];
    }else if ([theView isKindOfClass:[NSOutlineView class]]) {
        class = [LTWGUITreeViewAdapter class];
    }else if ([theView isKindOfClass:[NSComboBox class]] || [theView isKindOfClass:[NSPopUpButton class]]) {
        class = [LTWGUIComboBoxViewAdapter class];
    }else if ([theView isKindOfClass:[NSTextView class]]) {
        class = [LTWGUITextViewAdapter class];
    }else if ([theView isKindOfClass:[NSButton class]] || [theView isKindOfClass:[NSToolbarItem class]]) {
        class = [LTWGUIButtonViewAdapter class];
    }else if ([theRole isEqual:@"assessmentModeContainer"]) {
        class = [LTWGUIAssessmentContainerViewAdapter class];
    }else{
        class = [LTWGUIGenericViewAdapter class];
    }
#endif
    return class ? [(LTWGUIViewAdapter*)[class alloc] initWithView:theView role:theRole delegate:theDelegate] : nil;
}

+(LTWGUIViewAdapter*)adapterWithRole:(NSString*)role {
    return [roleDictionary objectForKey:role];
}

-(id)initWithView:(LTWGUIView*)theView role:(NSString*)theRole delegate:(id)theDelegate {
    if (self = [super init]) {
        role = [theRole retain];
        view = RETAIN_VIEW(theView);
        delegate = [theDelegate retain];
        nilSubstitute = nil;
        [self setUpView];
    }
    return self;
}

-(void)setUpView {
    return;
}

-(void)addObject:(id)object {
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
    if ([role isEqual:@"mainWindow"]) {
#ifdef GTK_PLATFORM
        gtk_widget_show_all(view);
#else
    
#endif
    }
}

-(void)addObject:(id)object {
    return;
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

-(void)displayModallyAbove:(LTWGUIWindowViewAdapter*)parent {
#ifdef GTK_PLATFORM
    if (GTK_IS_DIALOG(view)) {
        gtk_dialog_run(GTK_DIALOG(view));
        gtk_widget_hide(view);
    }
#else
    [NSApp beginSheet:(NSWindow*)view modalForWindow:(NSWindow*)(parent->view)
        modalDelegate:self didEndSelector:NULL contextInfo:nil];
#endif
}

-(void)hide {
#ifdef GTK_PLATFORM
    if (GTK_IS_DIALOG(view)) {
        gtk_dialog_response(GTK_DIALOG(view), GTK_RESPONSE_ACCEPT);
    }
#else
    [(NSWindow*)view orderOut:nil];
    [NSApp endSheet:(NSWindow*)view];
#endif
}

@end

@implementation LTWGUIStatusBarViewAdapter

-(void)setUpView {

}

-(void)addObject:(id)object {
#ifdef GTK_PLATFORM
    gtk_statusbar_push(GTK_STATUSBAR(view), gtk_statusbar_get_context_id(GTK_STATUSBAR(view), ""), [[object description] UTF8String]);
#else
    [(NSTextField*)view setStringValue:[object description]];
#endif
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

-(void)addObject:(id)object {
    if (![object isKindOfClass:[LTWGUIAssessmentMode class]]) return;
    
    static LTWGUIViewAdapter *assessmentMainView = nil;
    
#ifdef GTK_PLATFORM
    if (assessmentMainView) {
        gtk_container_remove(GTK_CONTAINER(view), assessmentMainView->view);
    }
#else
    while ([[(NSView*)view subviews] count] > 0) [[[(NSView*)view subviews] lastObject] removeFromSuperview];
#endif
    
    assessmentMainView = [LTWGUIViewAdapter loadViewsFromFile:[(LTWGUIAssessmentMode*)object GUIDefinitionFilename] withDelegate:delegate returningViewWithRole:@"assessmentMainView"];

    
#ifdef GTK_PLATFORM
    gtk_box_pack_end(GTK_BOX(view), assessmentMainView->view, TRUE, TRUE, 5);
#else
    [(NSView*)view addSubview:(NSView*)assessmentMainView->view];
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

@end

@implementation LTWGUIButtonViewAdapter

#ifdef GTK_PLATFORM
void LTWGUIButtonViewAdapter_clicked(GtkButton *button, LTWGUIButtonViewAdapter *adapter) {
    [adapter objectSelected:adapter];
}
#else
-(void)clicked:(id)sender {
    [self objectSelected:self];
}
#endif

-(void)setUpView {
#ifdef GTK_PLATFORM
    g_signal_connect(G_OBJECT(view), "clicked", G_CALLBACK(LTWGUIButtonViewAdapter_clicked), self);
#else
    [(NSControl*)view setTarget:self];
    [(NSControl*)view setAction:@selector(clicked:)];
#endif
}

-(void)addObject:(id)object {
    return;
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

@end


@implementation LTWGUIGenericTreeViewAdapter

#ifdef GTK_PLATFORM
-(void)handleToggleForColumn:(NSUInteger)columnIndex treePathString:(char*)treePathString {
    /*
    GtkTreePath *treePath = gtk_tree_path_new_from_string(treePathString);
    NSString *property = [columnProperties objectAtIndex:columnIndex];
    id object = [model objectAtTreePath:treePath];
    [object setValue:[NSNumber numberWithBool:![[object valueForKey:property] boolValue]] forKey:property];
    gtk_tree_path_free(treePath);
     */
}

void LTWGUIGenericTreeViewAdapter_toggled(GtkCellRendererToggle *cellRenderer, char *treePathString, LTWGUITreeViewAdapterColumn *column) {
    [column->adapter handleToggleForColumn:column->columnIndex treePathString:treePathString];
}
#endif

-(void)setUpColumnWithType:(LTWGUIDataType*)columnType name:(NSString*)columnName index:(NSUInteger)columnIndex {
#ifdef GTK_PLATFORM
    char *signalName = NULL;
    char *cellAttribute = NULL;
    void (*signalHandler)() = NULL;
    GtkCellRenderer *cellRenderer = NULL;
    
    switch(*columnType) {
        case G_TYPE_BOOLEAN:
            signalName = "toggled";
            cellAttribute = "active";
            signalHandler = LTWGUIGenericTreeViewAdapter_toggled;
            cellRenderer = gtk_cell_renderer_toggle_new();
            break;
        case G_TYPE_STRING:
        default:
            signalName = "edited";
            cellAttribute = "text";
            signalHandler = NULL;
            cellRenderer = gtk_cell_renderer_text_new();
            break;
    }
    
    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
        gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(view), -1, [columnName UTF8String], cellRenderer, cellAttribute, columnIndex, NULL);
    }else{
        gtk_cell_layout_pack_start(GTK_CELL_LAYOUT(view), cellRenderer, FALSE);
        gtk_cell_layout_set_attributes(GTK_CELL_LAYOUT(view), cellRenderer, cellAttribute, 0, NULL);
    }
    
    if (signalHandler) {
        LTWGUITreeViewAdapterColumn *columnReference = malloc(sizeof *columnReference);
        columnReference->adapter = self;
        columnReference->columnIndex = columnIndex;
        g_signal_connect(G_OBJECT(cellRenderer), signalName, G_CALLBACK(signalHandler), columnReference);
    }

#else
    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
        NSTableColumn *column = [[[NSTableColumn alloc] init] autorelease];
        [column setIdentifier:[NSNumber numberWithInt:columnIndex]];
        [[column headerCell] setStringValue:columnName];
        [(NSOutlineView*)view addTableColumn:column];
    }
#endif
}

-(void)attachModel:(LTWGUITreeModel*)theModel {
#ifdef GTK_PLATFORM
    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
        gtk_tree_view_set_model(GTK_TREE_VIEW(view), [model model]);
    }else{
        gtk_combo_box_set_model(GTK_COMBO_BOX(view), [model model]);
    }
#else
    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
        [(NSOutlineView*)view setDelegate:theModel];
        [(NSOutlineView*)view setDataSource:theModel];
        [(NSOutlineView*)view reloadData];
    }else{
        if ([view isKindOfClass:[NSComboBox class]]) {
            [(NSComboBox*)view setDelegate:theModel];
            [(NSComboBox*)view setUsesDataSource:YES];
            [(NSComboBox*)view setDataSource:theModel];
        }else{
            [(NSControl*)view setAction:@selector(selectionChangedAction:)];
            [(NSControl*)view setTarget:theModel];
        }
    }
    [theModel setDelegate:self];
#endif
}

-(void)setDisplayProperties:(NSArray*)displayProperties hierarchyProperties:(NSArray*)hierarchyProperties withClasses:(NSArray*)classes {    
    model = [[LTWGUITreeModel alloc] initWithDisplayProperties:displayProperties classes:classes];
    storedDisplayProperties = [displayProperties retain];
    storedHierarchyProperties = [hierarchyProperties retain];
    storedColumnClasses = [classes retain];
    

    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
#ifdef GTK_PLATFORM
        GtkTreeViewColumn *column = NULL;
        while (NULL != (column = gtk_tree_view_get_column(GTK_TREE_VIEW(view), 0))) {
            gtk_tree_view_remove_column(GTK_TREE_VIEW(view), column);
        }
#else
        while ([[(NSOutlineView*)view tableColumns] count] > 1) { // can't remove the outlineTableColumn
            [(NSOutlineView*)view removeTableColumn:[[(NSOutlineView*)view tableColumns] lastObject]];
        }
#endif
    }
    
    NSUInteger columnIndex = 0;
    for (NSValue *value in [model columnTypes]) {
        LTWGUIDataType *columnType = [value pointerValue];
        [self setUpColumnWithType:columnType name:[[displayProperties objectAtIndex:columnIndex] capitalizedString] index:columnIndex];
        columnIndex++;
    }
    
    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
#ifdef GTK_PLATFORM
        gtk_tree_view_columns_autosize(GTK_TREE_VIEW(view));
#else
    
#endif
    }
    
    [self attachModel:model];
    
    [model setHierarchyProperties:hierarchyProperties];
}

-(void)addObject:(id)object {
    [model addObject:object];
    
    //[LTWGUIUndoGroup addOperationToCurrentUndoGroup:[LTWGUIUndoableOperation operationAddingObject:object toView:self]];
    
#ifndef GTK_PLATFORM
    if ([view isKindOfClass:[NSPopUpButton class]]) {
        // NOTE: This won't work properly if things have been removed. Should really use the NSIndexPath returned by the model's addObject: method.
        [(NSPopUpButton*)view addItemWithTitle:[object description]];
    }
    
    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
        // NOTE: Passing nil here only works in 10.5+
        [(NSOutlineView*)view reloadItem:nil reloadChildren:YES];
    }else{
        if ([view isKindOfClass:[NSComboBox class]]) {
            [(NSComboBox*)view reloadData];
        }
    }
#endif
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    
#ifndef GTK_PLATFORM
    [view reloadData];
#endif
}

-(void)removeAllObjects {
    [self setDisplayProperties:storedDisplayProperties hierarchyProperties:storedHierarchyProperties withClasses:storedColumnClasses]; // creates and attaches a new model
    
#ifndef GTK_PLATFORM
    if ([self isKindOfClass:[LTWGUITreeViewAdapter class]]) {
        // NOTE: Passing nil here only works in 10.5+
        [(NSOutlineView*)view reloadItem:nil reloadChildren:YES];
    }else{
        if ([view isKindOfClass:[NSComboBox class]]) {
            [(NSComboBox*)view reloadData];
        }
    }
#endif
}

-(LTWGUITreeModel*)model {
    return model;
}

@end

@implementation LTWGUITreeViewAdapter

#ifdef GTK_PLATFORM
void LTWGUITreeViewAdapter_cursorChanged(GtkTreeView *view, LTWGUITreeViewAdapter *adapter) {
    GtkTreeSelection *selection = gtk_tree_view_get_selection(view);
    GtkTreeIter iter;
    GtkTreeModel *model;
    
    if (gtk_tree_selection_get_selected(selection, &model, &iter)) {
        GtkTreePath *path = gtk_tree_model_get_path(model, &iter);
        [adapter objectSelected:[[adapter model] objectAtTreePath:path]];
        
        gtk_tree_path_free(path);
    }else{
        [adapter objectSelected:nil];
    }
    
}

void LTWGUITreeViewAdapter_sizeAllocate(GtkTreeView *view, GtkAllocation *allocation, LTWGUITreeViewAdapter *adapter) {
    gtk_tree_view_columns_autosize(view);
}
#endif

-(void)setUpView {
#ifdef GTK_PLATFORM
    g_signal_connect(G_OBJECT(view), "cursor_changed", G_CALLBACK(LTWGUITreeViewAdapter_cursorChanged), self);
    //g_signal_connect(G_OBJECT(view), "size_allocate", G_CALLBACK(LTWGUITreeViewAdapter_sizeAllocate), self);
#else
    
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

@end

@implementation LTWGUIComboBoxViewAdapter

#ifdef GTK_PLATFORM
void LTWGUIComboBoxViewAdapter_changed(GtkComboBox *view, LTWGUIComboBoxViewAdapter *adapter) {
    NSInteger index = gtk_combo_box_get_active(view);
    id object = [[[adapter model] pathOfChildAtIndex:index parentPath:[NSArray array]] lastObject];
    [adapter objectSelected:object];
}
#endif

-(void)setUpView {
#ifdef GTK_PLATFORM
    model = nil;
    g_signal_connect(G_OBJECT(view), "changed", G_CALLBACK(LTWGUIComboBoxViewAdapter_changed), self);
#else
    [self setDisplayProperties:[NSArray arrayWithObject:@"description"] hierarchyProperties:[NSArray array] withClasses:[NSArray arrayWithObject:[NSObject class]]];
    [(NSComboBox*)view setFormatter:[[LTWGUIPathFormatter alloc] init]];
#endif
}

-(id <NSFastEnumeration>)objectsOfType:(Class*)type {
    return nil;
}

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

-(void)addObject:(id)object {
    if (![object isKindOfClass:[LTWTokens class]]) return;
#ifdef GTK_PLATFORM
    gtk_text_buffer_set_text(textBuffer, "", -1);
    
    // NOTE: Should turn this into a proper "deserializing" function.
    [self insertHTMLTokens:(LTWTokens*)object];
    
    // Note sure if this is necessary.
    gtk_text_view_set_buffer(GTK_TEXT_VIEW(view), textBuffer);
#else
    [[(NSTextView*)view textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:[object description]] autorelease]];
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

#ifndef GTK_PLATFORM

@implementation LTWGUIPathFormatter

-(NSString*)stringForObjectValue:(id)object {
    if ([object isKindOfClass:[NSArray class]]) {
        return [[object lastObject] description];
    }else{
        return [object description];
    }
}

-(BOOL)getObjectValue:(id*)object forString:(NSString*)string errorDescription:(NSString**)error {
    if (error) *error = @"Not implemented";
    return NO;
}

-(NSAttributedString*)attributedStringForObjectValue:(id)object withDefaultAttributes:(NSDictionary*)attributes {
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:object]] autorelease];
}

@end

#endif

@implementation LTWGUITreeModel

@synthesize delegate;

#pragma mark Initialisation

-(id)initWithDisplayProperties:(NSArray*)theDisplayProperties classes:(NSArray*)theClasses {
    if (self = [super init]) {
        
#ifdef GTK_PLATFORM
        static LTWGUIDataType booleanType = G_TYPE_BOOLEAN;
        static LTWGUIDataType stringType = G_TYPE_STRING;
#else
        static LTWGUIDataType booleanType = nil;
        if (!booleanType) booleanType = [NSNumber class];
        static LTWGUIDataType stringType = nil;
        if (!stringType) stringType = [NSString class];
#endif
        
        displayProperties = [theDisplayProperties retain];
    
        columnTypes = [[NSMutableArray alloc] init];
        
        for (NSString *propertyName in theDisplayProperties) {
            SEL propertySelector = NSSelectorFromString(propertyName);
            Class classWithProperty = nil;
            
            for (Class class in theClasses) {
                if ([class instancesRespondToSelector:propertySelector]) {
                    classWithProperty = class;
                    break;
                }
            }
            
            NSMethodSignature *signature = [classWithProperty instanceMethodSignatureForSelector:propertySelector];
            const char *returnType = [signature methodReturnType];
            
            if (strcmp(returnType, @encode(BOOL)) == 0) {
                [columnTypes addObject:[NSValue valueWithPointer:&booleanType]];
            }else{
                [columnTypes addObject:[NSValue valueWithPointer:&stringType]];
            }
        }
        
#ifdef GTK_PLATFORM
        LTWGUIDataType *tempTypes = malloc(sizeof tempTypes[0] * [columnTypes count]);
        for (NSUInteger index = 0; index < [columnTypes count]; index++) {
            tempTypes[index] = *(LTWGUIDataType*)[[columnTypes objectAtIndex:index] pointerValue];
        }
        model = GTK_TREE_MODEL(gtk_tree_store_newv([columnTypes count], tempTypes));
        free(tempTypes);
#endif
    }
    return self;
}

-(void)setHierarchyProperties:(NSArray*)properties {
    hierarchyProperties = [properties retain];
}

-(NSArray*)columnTypes {
    return columnTypes;
}

#pragma mark Hierarchy

-(NSMutableDictionary*)level:(NSUInteger)levelNumber {
    if (!levels) {
        levels = [[NSMutableArray alloc] init];
        [levels addObject:[NSMutableDictionary dictionary]];
        [[levels objectAtIndex:0] setObject:[NSIndexPath indexPathWithIndexes:NULL length:0] forKey:[NSArray array]];\
    }
    while (levelNumber >= [levels count]) {
        [levels addObject:[NSMutableDictionary dictionary]];
    }
    return [levels objectAtIndex:levelNumber];
}

-(NSUInteger)numberOfChildrenOfPath:(NSArray*)path {
    NSMutableDictionary *childLevel = [self level:[path count]+1];
    NSUInteger numChildren = 0;
    for (NSArray *childPath in childLevel) {
        if ([[childPath subarrayWithRange:NSMakeRange(0, [path count])] isEqual:path]) numChildren++;
    }
    return numChildren;
}

-(NSArray*)pathOfChildAtIndex:(NSUInteger)childIndex parentPath:(NSArray*)parentPath {
    NSMutableDictionary *parentLevel = [self level:[parentPath count]];
    NSIndexPath *parentIndexPath = [parentLevel objectForKey:parentPath];
    NSMutableDictionary *childLevel = [self level:[parentPath count]+1];
    for (NSArray *childPath in childLevel) {
        NSIndexPath *childIndexPath = [childLevel objectForKey:childPath];
        if ([childIndexPath isEqual:[parentIndexPath indexPathByAddingIndex:childIndex]]) return childPath;
    }
    return nil;
}

-(NSIndexPath*)rowReferenceForPath:(NSArray*)path {
    NSMutableDictionary *level = [self level:[path count]];
    NSIndexPath *rowReference = [level objectForKey:path];
    if (!rowReference) {
        NSArray *parentPath = [path subarrayWithRange:NSMakeRange(0, [path count] - 1)];
        NSIndexPath *parentIndexPath = [[self level:[parentPath count]] objectForKey:parentPath];
        
        NSUInteger newIndex = [self numberOfChildrenOfPath:parentPath];
        rowReference = [parentIndexPath indexPathByAddingIndex:newIndex];
        
        [level setObject:rowReference forKey:path];
        
#ifdef GTK_PLATFORM
        [self iteratorForIndexPath:rowReference];
#endif
    }
    return rowReference;
}

-(void)setRowReference:(NSIndexPath*)rowReference forPath:(NSArray*)path {
    if (rowReference) {
        [[self level:[path count]] setObject:rowReference forKey:path];
        
        // TODO: Implement GTK-specific stuff for this.
    }else{
        NSIndexPath *oldIndexPath = [[self level:[path count]] objectForKey:path];
        if (!oldIndexPath) return;
        
        [[self level:[path count]] removeObjectForKey:path];
        
        NSUInteger index = [oldIndexPath indexAtPosition:[oldIndexPath length]-1];
        
        for (NSArray *otherPath in [self level:[path count]]) {
            NSIndexPath *otherIndexPath = [[self level:[path count]] objectForKey:otherPath];
            NSUInteger otherIndex = [otherIndexPath indexAtPosition:[otherIndexPath length]-1];
            if (otherIndex > index) {
                [[self level:[path count]] setObject:[[otherIndexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:otherIndex-1] forKey:otherPath];
            }
            
        }
        
#ifdef GTK_PLATFORM
        GtkTreeIter iterator = [self iteratorForIndexPath:oldIndexPath];
        gtk_tree_store_remove(GTK_TREE_STORE(model), &iterator);
#endif
    }
}

#ifdef GTK_PLATFORM

#pragma mark GTK-specific

-(GtkTreeIter)iteratorForIndexPath:(NSIndexPath*)indexPath {
    GtkTreeIter parentIterator;
    GtkTreeIter *parentIteratorPointer = NULL;
    
    GtkTreePath *gtkPath = gtk_tree_path_new();
    for (NSUInteger pos = 0; pos < [indexPath length] - 1; pos++) {
        gtk_tree_path_append_index(gtkPath, [indexPath indexAtPosition:pos]);
    }
    
    if ([indexPath length] > 1) {
        gtk_tree_model_get_iter(model, &parentIterator, gtkPath);
        parentIteratorPointer = &parentIterator;
    }
    
    NSUInteger numChildren = gtk_tree_model_iter_n_children(model, parentIteratorPointer);
    NSUInteger childIndex = [indexPath indexAtPosition:[indexPath length]-1];
    
    GtkTreeIter iterator;
    
    if (childIndex < numChildren) {
        gtk_tree_model_iter_nth_child(model, &iterator, parentIteratorPointer, childIndex);
    }else{
        gtk_tree_store_append(GTK_TREE_STORE(model), &iterator, parentIteratorPointer);
    }
    
    return iterator;
}

-(id)objectAtTreePath:(GtkTreePath*)treePath {
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:gtk_tree_path_get_indices(treePath) length:gtk_tree_path_get_depth(treePath)];
    NSMutableDictionary *level = [self level:[indexPath length]];
    for (NSArray *path in level) {
        NSIndexPath *otherIndexPath = [level objectForKey:path];
        if ([indexPath length] != [otherIndexPath length]) continue;
        BOOL matched = YES;
        for (NSUInteger position = 0; position < [otherIndexPath length]; position++) {
            if ([indexPath indexAtPosition:position] != [otherIndexPath indexAtPosition:position]) {
                matched = NO;
                break;
            }
        }
        if (matched) {
            return [path lastObject];
        }
    }
    return nil;
}

-(void)setColumn:(NSUInteger)columnIndex indexPath:(NSIndexPath*)indexPath toValue:(id)value {
    GtkTreeIter iterator = [self iteratorForIndexPath:indexPath];
    
    switch (*(LTWGUIDataType*)[[columnTypes objectAtIndex:columnIndex] pointerValue]) {
        case G_TYPE_BOOLEAN:
            gtk_tree_store_set(GTK_TREE_STORE(model), &iterator, columnIndex, [(NSNumber*)value boolValue], -1);
            break;
            
        case G_TYPE_STRING:
        default:
            gtk_tree_store_set(GTK_TREE_STORE(model), &iterator, columnIndex, [[value description] UTF8String], -1);
            break;
    }
}

-(GtkTreeModel*)model {
    return model;
}

#else

#pragma mark Cocoa-specific

-(id)outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item {
    if (!item) item = [NSArray array];
    return [self pathOfChildAtIndex:index parentPath:item];
}

-(BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item {
    if (!item) item = [NSArray array];
    return [self numberOfChildrenOfPath:item] > 0;
}

-(NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) item = [NSArray array];
    return [self numberOfChildrenOfPath:item];
}

-(id)outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item {
    NSString *hierarchyPropertyName = nil;
    if ([item isKindOfClass:[NSArray class]]) {
        if ([(NSArray*)item count] <= [hierarchyProperties count]) hierarchyPropertyName = [hierarchyProperties objectAtIndex:[(NSArray*)item count]-1];
        item = [(NSArray*)item lastObject];
    }
    NSUInteger columnIndex = [[tableColumn identifier] intValue];
    NSString *propertyName = [displayProperties objectAtIndex:columnIndex];
    if ([hierarchyPropertyName isEqual:propertyName]) propertyName = @"self";
    if (!propertyName) return @"";
    if (![item respondsToSelector:NSSelectorFromString(propertyName)]) return @"";
    id value = [item valueForKey:propertyName];
    if (!value) return @"";
    return [value description];
}

-(BOOL)outlineView:(NSOutlineView*)outlineView shouldSelectItem:(id)item {
    if ([item isKindOfClass:[NSArray class]]) item = [(NSArray*)item lastObject];
    [delegate objectSelected:item];
    return YES;
}

-(id)comboBox:(NSComboBox*)comboBox objectValueForItemAtIndex:(NSInteger)index {
    return [self pathOfChildAtIndex:index parentPath:[NSArray array]];
}

-(NSInteger)numberOfItemsInComboBox:(NSComboBox*)comboBox {
    return [self numberOfChildrenOfPath:[NSArray array]];
}

-(void)comboBoxSelectionDidChange:(NSNotification*)notification {
    NSUInteger index = [[notification object] indexOfSelectedItem];
    id object = [[self pathOfChildAtIndex:index parentPath:[NSArray array]] lastObject];
    [delegate objectSelected:object];
}

-(void)selectionChangedAction:(id)sender {
    NSUInteger index = [sender indexOfSelectedItem];
    id object = [[self pathOfChildAtIndex:index parentPath:[NSArray array]] lastObject];
    [delegate objectSelected:object];
}

#endif

#pragma mark General

-(NSIndexPath*)addObject:(id)object {
    NSMutableArray *path = [NSMutableArray array];
    
    NSIndexPath *indexPath = nil;
    
    for (NSString *propertyName in [hierarchyProperties arrayByAddingObject:@"self"]) {
        id value = [object valueForKey:propertyName];
        [path addObject:value];
        indexPath = [self rowReferenceForPath:path]; // creates the reference if it doesn't yet exist
        
#ifdef GTK_PLATFORM
        NSUInteger columnIndex = 0;
        for (NSString *displayPropertyName in displayProperties) {
            if ([displayPropertyName isEqual:propertyName]) displayPropertyName = @"self";
            
            if ([value respondsToSelector:NSSelectorFromString(displayPropertyName)]) {
                id columnValue = [value valueForKey:displayPropertyName];
                if (!columnValue) columnValue = @"";
                [self setColumn:columnIndex indexPath:indexPath toValue:columnValue];
            }
            
            columnIndex++;
        }
#endif
    }
    
    return indexPath;
}

-(void)moveObject:(id)object {
    // TEMP
    NSLog(@"Skipping moveObject...");
    return;
}

-(void)changeObject:(id)object newValue:(id)newValue forColumn:(NSUInteger)columnIndex {
#ifdef GTK_PLATFORM
    NSMutableArray *path = [NSMutableArray array];
    
    for (NSString *propertyName in [hierarchyProperties arrayByAddingObject:@"self"]) {
        [path addObject:[object valueForKey:propertyName]];
        [self rowReferenceForPath:path]; // creates the reference if it doesn't yet exist
    }
    
    [self setColumn:columnIndex indexPath:[self rowReferenceForPath:path] toValue:newValue];
#endif
}

-(void)removeObject:(id)object {
    NSMutableArray *path = [NSMutableArray array];
    
    for (NSString *propertyName in [hierarchyProperties arrayByAddingObject:@"self"]) {
        [path addObject:[object valueForKey:propertyName]];
    }
    
    [self setRowReference:nil forPath:path];
    //[self trimHierarchy:hierarchyValues];
}


@end


@implementation NSIndexPath (BugFixes)

-(BOOL)isEqual:(id)other {
    return [other isKindOfClass:[NSIndexPath class]] && [self compare:other] == NSOrderedSame;
}

-(NSIndexPath*)indexPathByAddingIndex:(NSUInteger)index {
    NSUInteger *indexes = malloc(sizeof indexes[0] * ([self length] + 1));
    [self getIndexes:indexes];
    indexes[[self length]] = index;
    NSIndexPath *newIndexPath = [NSIndexPath indexPathWithIndexes:indexes length:[self length]+1];
    free(indexes);
    return newIndexPath;
}

@end

#ifndef GTK_PLATFORM

@implementation NSObject (Roles)

static NSMutableDictionary *roles = nil;

-(NSString*)role {
    if (!roles) roles = [[NSMutableDictionary alloc] init];
    id object = [self isKindOfClass:[NSToolbarItem class]] ? [(NSToolbarItem*)self view] : self;
    return [roles objectForKey:[NSValue valueWithNonretainedObject:object]];
}

-(void)setRole:(NSString*)role {
    if (!roles) roles = [[NSMutableDictionary alloc] init];
    id object = ![self isKindOfClass:[NSToolbarItem class]] ? self : [(NSToolbarItem*)self view] ? [(NSToolbarItem*)self view] : self;
    [roles setObject:role forKey:[NSValue valueWithNonretainedObject:object]];
    [roleDictionary setObject:[LTWGUIViewAdapter adapterForView:object role:role delegate:delegateForLoadedViews] forKey:role];
}

@end
#endif