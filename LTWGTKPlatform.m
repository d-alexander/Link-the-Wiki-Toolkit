//
//  LTWGTKPlatform.m
//  LTWToolkit
//
//  Created by David Alexander on 17/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#ifdef GTK_PLATFORM

#import "LTWGTKPlatform.h"
#import "LTWAssessmentController.h"

#import "LTWTokens.h"
#import "LTWRemoteDatabase.h"
#import "LTWOverlayTokensView.h"

@implementation LTWGTKPlatform

#pragma mark LTWGUIPlatform

static LTWGTKPlatform *sharedInstance = nil;
+(LTWGTKPlatform*)sharedInstance {
    if (!sharedInstance) sharedInstance = [[LTWGTKPlatform alloc] init];
    return sharedInstance;
}

// NOTE: The GTK platform technically shouldn't have to return its main view, since it handles the placement of that view itself. Perhaps this should be removed from the LTWGUIPlatform protocol.
-(GtkWidget*)mainView {
    return mainView;
}

-(GtkWidget*)componentWithRole:(NSString*)role inView:(GtkWidget*)view {
    // NOTE: This currently doesn't limit the search to the given view.
    GObject *object = gtk_builder_get_object(builder, [role UTF8String]);
    if (!object) return NULL;
    return GTK_WIDGET(object);
}

// Consider adding this to the LTWGUIPlatform protocol.
-(NSString*)roleForComponent:(GtkWidget*)component {
    return [NSString stringWithUTF8String:gtk_buildable_get_name(GTK_BUILDABLE(component))];
}

gboolean checkForNewAssessments(void *data) {
    NSDictionary *newAssessments = [[LTWAssessmentController sharedInstance] assessmentsReady];
    NSLog(@"Checking...");
    if (newAssessments) {
        NSLog(@"New assessments!");
        [newAssessments retain];
        [[LTWAssessmentController sharedInstance] setAssessmentsReady:nil];
        
        // NOTE: Currently the new assessments overwrite any old ones!
        [[LTWGTKPlatform sharedInstance] setRepresentedValue:newAssessments forRole:@"articleSelector"];
    }
    return YES;
}

// This is equivalent to the applicationDidFinishLaunching method in NSApplicationDelegate, except that at the end it starts GTK's runloop.
// Later, we will want to drive the runloop manually (which GTK does allow) for two reasons: to handle NSAutoreleasePools and to provide an NSRunLoop to enable features such as performSelectorOnMainThread:.
-(void)run {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    builder = gtk_builder_new();
    gtk_builder_add_from_file(builder, "\\\\vmware-host\\Shared Folders\\VMWare Shared\\LTWAssessmentTool-Windows.app\\Contents\\Resources\\MainWindow.glade", NULL);
    GtkWidget *mainWindow = GTK_WIDGET(gtk_builder_get_object(builder, "mainWindow"));
    gtk_widget_show_all(mainWindow);
    
    NSArray *assessmentModes = [[NSArray arrayWithObject:@"No assessment mode"] arrayByAddingObjectsFromArray:[[LTWAssessmentController sharedInstance] assessmentModes]];
    
    [self setRepresentedValue:assessmentModes forRole:@"assessmentModeSelector"];
    
    g_timeout_add_seconds(1, checkForNewAssessments, NULL);
    
    LTWRemoteDatabase *remoteDatabase = [[LTWRemoteDatabase alloc] init];
    
    NSThread *thread = [[NSThread alloc] initWithTarget:remoteDatabase selector:@selector(startDownloadThread) object:nil];
    [thread start];
    
    gtk_main();
    
    [pool drain];
}

-(void)loadNewArticles {
    
}

#pragma mark Miscellaneous

- (id)init {
    if ((self = [super init])) {
        assessmentMode = nil;
        // NOTE: Our sharedInstance will not be available until AFTER the init method runs, so we mustn't start the run-loop here. That happens in -[LTWGTKPlatform run].
        
        [[LTWAssessmentController sharedInstance] setPlatform:self];
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

#pragma mark Private

void addOverlayForTextView(GtkTextView *textView, NSUInteger firstToken, NSUInteger lastToken); // forward declaration

-(void)selectionChangedTo:(id)newSelection forRole:(NSString*)role {
    NSLog(@"%@'s selection changed to %@", role, newSelection);
    
    if ([role isEqual:@"assessmentModeSelector"]) {
        assessmentMode = newSelection;
        
        // Need to resize the main view and display the assessment mode view as in LTWCocoaPlatform.
        
        // NOTE: This could cause naming conflicts between the assessment mode view and the rest of the UI. We could get around this by using multiple GtkBuilders.
        gtk_builder_add_from_file(builder, [assessmentMode mainViewForPlatform:self], NULL);
        
        GtkWidget *assessmentMainView = GTK_WIDGET(gtk_builder_get_object(builder, "mainView"));
        
        // TEMP
        gtk_widget_show_all(assessmentMainView);

        
        // NOTE: Should also redo all value-assignments for roles here (so that, for example, if an article is selected in the old assessment mode it will still be selected in the new one).
    }else if ([role isEqual:@"articleSelector"]) {
        LTWArticle *article = newSelection; // NOTE: The Cocoa platform takes newSelection as the URL, not the LTWArticle itself; should we do so as well?
        [self setRepresentedValue:[article tokensForField:@"body"] forRole:@"sourceArticleBody"];
        [self setRepresentedValue:[[article tokensForField:@"title"] description] forRole:@"sourceArticleTitle"];
        [self setRepresentedValue:[[LTWAssessmentController sharedInstance] targetTreeForArticle:article] forRole:@"sourceArticleLinks"];
        
        // TEMP
        addOverlayForTextView(GTK_TEXT_VIEW([self componentWithRole:@"sourceArticleBody" inView:[self mainView]]), 3, 5);
        
    }else if ([role isEqual:@"sourceArticleLinks"]) {
        LTWArticle *article = [[LTWAssessmentController sharedInstance] articleWithURL:newSelection];
        [self setRepresentedValue:[article tokensForField:@"body"] forRole:@"targetArticleBody"];
        [self setRepresentedValue:[[article tokensForField:@"title"] description] forRole:@"targetArticleTitle"];
    }
}

-(void)selectionChangedTo:(id)newSelection forComponent:(GtkWidget*)component {
    if (!component) return;
    
    NSString *role = [self roleForComponent:component];
    if (!role) return;
    /*
    if (assessmentMode && [self componentWithRole:role inView:[assessmentMode mainViewForPlatform:self]] == component) {
        [assessmentMode selectionChangedTo:newSelection forRole:role];
    }else{
     */
        [self selectionChangedTo:newSelection forRole:role];
    /*
    }
     */
}

static NSMutableDictionary *representedValues = nil; // Stores data that is currently being shown.

void comboBoxSelectionChanged(GtkComboBox *sender, void *data) {
    if (!representedValues) representedValues = [[NSMutableDictionary alloc] init];
    id representedValue = [representedValues objectForKey:[NSValue valueWithPointer:sender]];
    if (!representedValue) return;
    NSArray *array;
    if ([representedValue isKindOfClass:[NSArray class]]) {
        array = (NSArray*)representedValue;
    }else if ([representedValue isKindOfClass:[NSDictionary class]]) {
        array = [(NSDictionary*)representedValue allKeys];
    }else{
        return;
    }
    
    NSInteger selectedIndex = gtk_combo_box_get_active(sender);
    if (selectedIndex >= [array count]) return;
    
    id selectedValue = [array objectAtIndex:selectedIndex];
    if ([representedValue isKindOfClass:[NSDictionary class]]) selectedValue = [(NSDictionary*)representedValue objectForKey:selectedValue];
    
    [[LTWGTKPlatform sharedInstance] selectionChangedTo:selectedValue forComponent:GTK_WIDGET(sender)];
}

void treeViewSelectionChanged(GtkTreeView *sender, void *data) {
    if (!representedValues) representedValues = [[NSMutableDictionary alloc] init];
    id representedValue = [representedValues objectForKey:[NSValue valueWithPointer:sender]];
    if (!representedValue) return;
    NSArray *array;
    if ([representedValue isKindOfClass:[NSArray class]]) {
        array = (NSArray*)representedValue;
    }else if ([representedValue isKindOfClass:[NSDictionary class]]) {
        array = [(NSDictionary*)representedValue allKeys];
    }else{
        return;
    }
    
    GtkTreeSelection *selection = gtk_tree_view_get_selection(sender);
    GtkTreeIter iter;
    GtkTreeModel *model;
    if (gtk_tree_selection_get_selected(selection, &model, &iter)) {
        GtkTreePath *path = gtk_tree_model_get_path(model, &iter);
        NSUInteger selectedIndex = gtk_tree_path_get_indices(path)[0];
        NSLog(@"selectedIndex = %u", selectedIndex);
        if (selectedIndex >= [array count]) return;
        id selectedValue = [array objectAtIndex:selectedIndex];
        if ([representedValue isKindOfClass:[NSDictionary class]]) selectedValue = [(NSDictionary*)representedValue objectForKey:selectedValue];
        [[LTWGTKPlatform sharedInstance] selectionChangedTo:selectedValue forComponent:GTK_WIDGET(sender)];
        gtk_tree_path_free(path);
    }else{
        // NOTE: Should we do anything with a nil selection?
    }
}

typedef struct {
    GtkTextTag *tag;
    GtkTextMark *start;
} HTMLConversionStackEntry;

BOOL tagForXMLToken(LTWTokens *tokens, NSUInteger tokenIndex, GtkTextBuffer *buffer, GtkTextTag **tag) {
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

void insertHTMLTokensIntoBuffer(GtkTextBuffer *buffer, LTWTokens *tokens, GtkTextMark ***tokenStartMarks, GtkTextMark ***tokenEndMarks) {
    NSMutableArray *stack = [NSMutableArray array];
    
    NSUInteger numTokens = [tokens count];
    NSString *tokensText = [tokens _text];
    
    *tokenStartMarks = malloc(numTokens * sizeof **tokenStartMarks);
    *tokenEndMarks = malloc(numTokens * sizeof **tokenEndMarks);
    
    for (NSUInteger tokenIndex = 0; tokenIndex < numTokens; tokenIndex++) {
        (*tokenStartMarks)[tokenIndex] = NULL;
        (*tokenEndMarks)[tokenIndex] = NULL;
        
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
                gtk_text_buffer_get_iter_at_mark(buffer, &start, entry->start);
                gtk_text_buffer_get_end_iter(buffer, &end);
                gtk_text_buffer_apply_tag(buffer, entry->tag, &start, &end);
            }
        }else if (isXML) { // start tag
            // NOTE: This is messy. The tagForXMLToken function determines what the GtkTextTag should be for a given XML start tag, but sometimes there shouldn't be a tag, and sometimes we shouldn't even add an HTMLConversionStackEntry because the XML tag won't have a corresponding end-tag.
            // So, we return the GtkTextTag itself through a pointer (which may be NULL) and the return value specifies whether to add an entry to the stack at all.
            // It is possible for an XML tag not to result in an entry being created, despite having an effect on the buffer (e.g. <br> inserts a newline). Therefore, we also pass the buffer itself.
            GtkTextTag *tag = NULL;
            BOOL addEntry = tagForXMLToken(tokens, tokenIndex, buffer, &tag);
            
            if (addEntry) {
                HTMLConversionStackEntry *entry = malloc(sizeof *entry);
            
                // NOTE: Should probably reuse tags when we want to create identical text properties more than once.
                entry->tag = tag;
            
                // Would it be better to create two marks -- start and end -- with left and right gravity respecively, and then insert the text "between" the marks? Would this be more efficient?
                entry->start = gtk_text_mark_new(NULL, YES); // create mark with left gravity and no name
                GtkTextIter iter;
                gtk_text_buffer_get_end_iter(buffer, &iter);
                gtk_text_buffer_add_mark(buffer, entry->start, &iter);
                
                [stack addObject:[NSValue valueWithPointer:entry]];
            }
        }else{ // not XML
            (*tokenStartMarks)[tokenIndex] = gtk_text_mark_new(NULL, YES);
            (*tokenEndMarks)[tokenIndex] = gtk_text_mark_new(NULL, YES);
            
            GtkTextIter iter;
            gtk_text_buffer_get_end_iter(buffer, &iter);
            gtk_text_buffer_add_mark(buffer, (*tokenStartMarks)[tokenIndex], &iter);
            gtk_text_buffer_insert(buffer, &iter, [[tokensText substringWithRange:[tokens rangeOfTokenAtIndex:tokenIndex]] UTF8String], -1);
            gtk_text_buffer_get_end_iter(buffer, &iter);
            gtk_text_buffer_add_mark(buffer, (*tokenEndMarks)[tokenIndex], &iter);
            gtk_text_buffer_insert(buffer, &iter, " ", 1);
        }
    }
    
}

void textViewExposed(GtkTextView *textView, GdkEventExpose *event); // forward declaration

static NSMutableDictionary *textViewStartMarks = nil;
static NSMutableDictionary *textViewEndMarks = nil;

void addTextViewMarks(GtkTextView *textView, GtkTextMark **startMarks, GtkTextMark **endMarks) {
    if (!textViewStartMarks) textViewStartMarks = [[NSMutableDictionary alloc] init];
    if (!textViewEndMarks) textViewEndMarks = [[NSMutableDictionary alloc] init];
    
    [textViewStartMarks setObject:[NSValue valueWithPointer:startMarks] forKey:[NSValue valueWithPointer:textView]];
    [textViewEndMarks setObject:[NSValue valueWithPointer:endMarks] forKey:[NSValue valueWithPointer:textView]];
}

void getTextViewMarks(GtkTextView *textView, GtkTextMark ***startMarks, GtkTextMark ***endMarks) {
    if (!textViewStartMarks) textViewStartMarks = [[NSMutableDictionary alloc] init];
    if (!textViewEndMarks) textViewEndMarks = [[NSMutableDictionary alloc] init];
    
    *startMarks = [[textViewStartMarks objectForKey:[NSValue valueWithPointer:textView]] pointerValue];
    *endMarks = [[textViewEndMarks objectForKey:[NSValue valueWithPointer:textView]] pointerValue];
}

-(void)setRepresentedValue:(id)value forRole:(NSString*)role {
    // This tries to "translate" the given value into something that can be displayed by the view.
    
    GtkWidget *component = [self componentWithRole:role inView:[self mainView]];
    
    BOOL success = NO;
    
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
        GtkTreeStore *store;
        if ([role isEqual:@"sourceArticleLinks"]) {
            store = gtk_tree_store_new(2, G_TYPE_STRING, G_TYPE_BOOLEAN);
        }else{
            store = gtk_tree_store_new(1, G_TYPE_STRING);
        }
        
        GtkTreeIter iterator;
        
        
        NSArray *array = [value isKindOfClass:[NSDictionary class]] ? [(NSDictionary*)value allKeys] : (NSArray*)value;
        for (id item in array) {
            NSLog(@"adding %@", item);
            gtk_tree_store_append(store, &iterator, NULL);
            if ([role isEqual:@"sourceArticleLinks"]) {
                gtk_tree_store_set(store, &iterator, 0, [[item description] UTF8String], 1, FALSE, -1);
            }else{
                gtk_tree_store_set(store, &iterator, 0, [[item description] UTF8String], -1);
            }
        }
        
        if (GTK_IS_TREE_VIEW(component)) {
            
            NSLog(@"creating cells");
                
            GtkCellRenderer *cell = gtk_cell_renderer_text_new ();
            gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (component), -1,                                     "Title", cell,                                                             "text", 0,                                                             NULL);
            
            if ([role isEqual:@"sourceArticleLinks"]) {
                GtkCellRenderer *cell2 = gtk_cell_renderer_toggle_new ();
                gtk_tree_view_insert_column_with_attributes (GTK_TREE_VIEW (component),
                                                             -1,      
                                                             "Relevant?",  
                                                             cell2,
                                                             NULL);
                
            }
            
            

            
            gtk_tree_view_set_model(GTK_TREE_VIEW(component), GTK_TREE_MODEL(store));
            // NOTE: The documentation says "cursor-changed"; why doesn't it work unless I change it to "cursor_changed"?
            g_signal_connect(G_OBJECT(component), "cursor_changed", G_CALLBACK(treeViewSelectionChanged), NULL);
            if (!representedValues) representedValues = [[NSMutableDictionary alloc] init];
            [representedValues setObject:value forKey:[NSValue valueWithPointer:component]];
            success = YES;
        }else if (GTK_IS_COMBO_BOX(component)) {
            
            GtkCellRenderer *cell = gtk_cell_renderer_text_new();
            gtk_cell_layout_pack_start( GTK_CELL_LAYOUT( component ), cell, FALSE );
            gtk_cell_layout_set_attributes( GTK_CELL_LAYOUT( component ), cell,
                                           "text", 0,
                                           NULL ); 
            
            gtk_combo_box_set_model(GTK_COMBO_BOX(component), GTK_TREE_MODEL(store));
            g_signal_connect(G_OBJECT(component), "changed", G_CALLBACK(comboBoxSelectionChanged), NULL);
            if (!representedValues) representedValues = [[NSMutableDictionary alloc] init];
            [representedValues setObject:value forKey:[NSValue valueWithPointer:component]];
            success = YES;
        }
        
    }else if ([value isKindOfClass:[LTWTokens class]]) {
        if (GTK_IS_TEXT_VIEW(component)) {
            GtkTextBuffer *buffer = gtk_text_buffer_new(NULL);
            
            GtkTextMark **startMarks, **endMarks;
            
            // NOTE: Should turn this into a proper "deserializing" function.
            insertHTMLTokensIntoBuffer(buffer, (LTWTokens*)value, &startMarks, &endMarks);
            
            gtk_text_view_set_buffer(GTK_TEXT_VIEW(component), buffer);
            
            // NOTE: Should be making sure to only do this once!
            g_signal_connect(G_OBJECT(component), "expose_event", G_CALLBACK(textViewExposed), NULL);
            
            addTextViewMarks(GTK_TEXT_VIEW(component), startMarks, endMarks);
            
            success = YES;
        }
    }

    if (!success) {
        NSLog(@"Unable to represent %@ in %@.", value, self);
    }
     
}

NSMutableArray *overlaysForTextView(GtkTextView *textView) {
    static NSMutableDictionary *textViewOverlays = nil;
    if (!textViewOverlays) textViewOverlays = [[NSMutableDictionary alloc] init];
    NSMutableArray *array = [textViewOverlays objectForKey:[NSValue valueWithPointer:textView]];
    if (!array) {
        array = [NSMutableArray array];
        [textViewOverlays setObject:array forKey:[NSValue valueWithPointer:textView]];
    }
    return array;
}

void addOverlayForTextView(GtkTextView *textView, NSUInteger firstToken, NSUInteger lastToken) {
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(textView);
    
    GtkTextMark **startMarks, **endMarks;
    getTextViewMarks(textView, &startMarks, &endMarks);
    
    while (firstToken <= lastToken && !startMarks[firstToken]) firstToken++;
    while (firstToken <= lastToken && !endMarks[lastToken]) lastToken--;
    if (firstToken > lastToken) return;
    
    GtkTextIter start, end;
    gtk_text_buffer_get_iter_at_mark(buffer, &start, startMarks[firstToken]);
    gtk_text_buffer_get_iter_at_mark(buffer, &end, endMarks[lastToken]);
    
    GdkRectangle startRect, endRect;
    gtk_text_view_get_iter_location(textView, &start, &startRect);
    gtk_text_view_get_iter_location(textView, &end, &endRect);
    
    GdkRectangle entireRect;
    gdk_rectangle_union(&startRect, &endRect, &entireRect);
    
    LTWOverlayRect *overlayRect = [[[LTWOverlayRect alloc] initWithGtkTextView:textView characterRange:NSMakeRange(0, 0) gdkRect:entireRect] autorelease];
    [overlaysForTextView(textView) addObject:overlayRect];
}

// Called from "expose-event" handler.
void drawOverlaysForTextView(GtkTextView *textView, GdkPixmap *pixmap, GdkGC *gc) {
    GdkColor color;
    gdk_color_parse("red", &color);
    gdk_gc_set_foreground(gc, &color);
    
    // NOTE: Later we'll want to use LTWOverlayLayer or something similar, rather than just the rect -- otherwise we can't store text, etc, to go inside the overlay.
    for (LTWOverlayRect *overlayRect in overlaysForTextView(textView)) {
        NSRect frame = [overlayRect frame];
        NSLog(@"Drawing an overlay with frame (%f, %f, %f, %f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        gdk_draw_rectangle(pixmap, gc, TRUE, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    }
}

void textViewExposed(GtkTextView *textView, GdkEventExpose *event) {
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
}

@end

#endif
