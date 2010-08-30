//
//  main.m
//  LTWNibTranslator
//
//  Created by David Alexander on 30/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

typedef enum {
    UNKNOWN, HORIZONTAL, VERTICAL
} BoxType;

void printIndented(FILE *file, int depth, const char *format, ...) {
    for (NSUInteger i=0; i<depth; i++) fprintf(file, "  ");
    va_list vl;
    va_start(vl, format);
    vfprintf(file, format, vl);
    va_end(vl);
    fprintf(file, "\n");
}

const char *className(id object) {
    if ([object isKindOfClass:[NSButton class]]) {
        return "GtkButton";
    }else if ([object isKindOfClass:[NSComboBox class]]) {
        return "GtkComboBox";
    }else if ([object isKindOfClass:[NSTextField class]]) {
        return [(NSTextField*)object isEditable] ? "GtkLabel" : "GtkEntry";
    }else if ([object isKindOfClass:[NSTextView class]]) {
        return "GtkTextView";
    }else if ([object isKindOfClass:[NSOutlineView class]]) {
        return "GtkTreeView";
    }else if ([object isMemberOfClass:[NSView class]]) {
        return "NSVIEW_PLACEHOLDER";
    }else{
        return [[[object class] description] UTF8String];
    }
}

void printProperties(FILE *file, int depth, NSDictionary *properties) {
    
    for (id property in properties) {
        printIndented(file, depth, "<property name=\"%s\">%s</property>", [[property description] UTF8String], [[[properties objectForKey:property] description] UTF8String]);
    }
}

void printXMLStart(FILE *file) {
    printIndented(file, 0, "<?xml version=\"1.0\"?>");
    printIndented(file, 0, "<interface>");
    printIndented(file, 1, "<requires lib=\"gtk+\" version=\"2.16\"/>");
    printIndented(file, 1, "<!-- interface-naming-policy project-wide -->");
    printIndented(file, 1, "<object class=\"GtkWindow\" id=\"mainWindow\">");
    
}

void printXMLEnd(FILE *file) {
    printIndented(file, 1, "</object>");    
    printIndented(file, 0, "</interface>");
}

@interface DummyDelegate : NSObject {
    
}
@end
@implementation DummyDelegate

@end
@class BoxBox;
@interface Box : NSObject {
}
-(BOOL)shouldExpandInBoxOfType:(BoxType)theBoxType;
-(NSRect)rect;
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth parent:(BoxBox*)parent;
-(NSComparisonResult)compareToBox:(Box*)theBox;
@end
@interface ViewBox : Box {
    NSView *view;
}
@end
@interface BoxBox : Box {
    NSArray *boxes;
    BoxType type;
}
-(BoxBox*)boxByTryingToAddChildBox:(Box*)theBox;
-(NSArray*)boxes;
-(BoxType)type;
@end

@implementation Box
-(NSRect)rect {
    return NSZeroRect;
}
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth parent:(BoxBox*)parent {
}
-(BOOL)shouldExpandInBoxOfType:(BoxType)theBoxType {
    return NO;
}
-(NSComparisonResult)compareToBox:(Box*)theBox {
    NSRect rect = [self rect];
    NSRect otherRect = [theBox rect];
    if (NSMinX(rect) < NSMinX(otherRect)) return NSOrderedAscending;
    if (NSMinX(rect) > NSMinX(otherRect)) return NSOrderedDescending;
    if (NSMinY(rect) < NSMinY(otherRect)) return NSOrderedAscending;
    if (NSMinY(rect) > NSMinY(otherRect)) return NSOrderedDescending;
    return NSOrderedSame;
}
@end

@implementation ViewBox
-(NSString*)description {
    return [NSString stringWithFormat:@"ViewBox { view = %@, rect = %@ }", view, NSStringFromRect([self rect])];
}
-(BOOL)shouldExpandInBoxOfType:(BoxType)theBoxType {
    return [view autoresizingMask] & (theBoxType == VERTICAL ? NSViewHeightSizable : NSViewWidthSizable);
}
-(id)initWithView:(NSView*)theView {
    if (self = [super init]) {
        while (YES) {
            if ([theView isKindOfClass:[NSScrollView class]]) {
                theView = [(NSScrollView*)theView documentView];
            }else{
                break;
            }
        }
        view = [theView retain];
    }
    return self;
}
-(NSRect)rect {
    return [view frame];
}
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth parent:(BoxBox*)parent {
    printIndented(file, depth, "<child>");
    printIndented(file, depth+1, "<object class=\"%s\">", className(view));
    printProperties(file, depth+2, [NSDictionary dictionaryWithObjectsAndKeys:(!parent || [self shouldExpandInBoxOfType:[parent type]] ? @"True" : @"False"), @"expand", [NSValue valueWithRect:[self rect]], @"rect (TEMP)", view, @"Cocoa View (TEMP(", nil]);
    printIndented(file, depth+1, "</object>");
    printIndented(file, depth, "</child>");
}
@end

@implementation BoxBox
-(NSString*)description {
    return [NSString stringWithFormat:@"BoxBox { type = %@, rect = %@, boxes = %@ }", (type == UNKNOWN ? @"UNKNOWN" : type == HORIZONTAL ? @"HORIZONTAL" : @"VERTICAL"), NSStringFromRect([self rect]), boxes];
}
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth parent:(BoxBox*)parent {
    printIndented(file, depth, "<child>");
    printIndented(file, depth+1, "<object class=\"%s\" id=\"ID_HERE\">", type == HORIZONTAL ? "GtkHBox" : "GtkVBox");
    
    printProperties(file, depth+2, [NSDictionary dictionaryWithObjectsAndKeys:(!parent || [self shouldExpandInBoxOfType:[parent type]] ? @"True" : @"False"), @"expand",nil]);
    
    for (Box *box in boxes) {
        [box printXMLTo:file depth:depth+2 parent:self];
    }
    
    printIndented(file, depth+1,  "</object>");
    printIndented(file, depth, "</child>");
}
-(BOOL)shouldExpandInBoxOfType:(BoxType)theBoxType {
    return theBoxType != type;
}
-(id)init {
    if (self = [super init]) {
        boxes = [[NSMutableArray alloc] init];
        type = UNKNOWN;
    }
    return self;
}
-(BoxBox*)boxByTryingToAddChildBox:(Box*)theBox {
    NSMutableArray *newBoxes = [boxes mutableCopy];
    BoxType newType = type;
    if (type == UNKNOWN && [boxes count] == 0) {
        [newBoxes addObject:theBox];
    }else{
        
        NSRect rect = [self rect];
        NSRect otherRect = [theBox rect];
        NSUInteger minXDiff = abs( NSMinX(rect) - NSMinX(otherRect) );
        NSUInteger minYDiff = abs( NSMinY(rect) - NSMinY(otherRect) );
        NSUInteger maxXDiff = abs( NSMaxX(rect) - NSMaxX(otherRect) );
        NSUInteger maxYDiff = abs( NSMaxY(rect) - NSMaxY(otherRect) );
        const NSUInteger tolerance = 10;
        
        if (newType == UNKNOWN || newType == VERTICAL) {
            if (minXDiff <= tolerance && maxXDiff <= tolerance) {
                newType = VERTICAL;
                [newBoxes addObject:theBox];
            }
        }
        if (newType == UNKNOWN || newType == HORIZONTAL) {
            if (minYDiff <= tolerance && maxYDiff <= tolerance) {
                newType = HORIZONTAL;
                [newBoxes addObject:theBox];
            }
        }
    }
    
    BoxBox *newBox = [[BoxBox alloc] init];
    newBox->boxes = newBoxes;
    newBox->type = newType;
    return [newBox autorelease];
}
-(BoxType)type {
    return type;
}
-(NSArray*)boxes {
    return boxes;
}
-(NSRect)rect {
    NSRect rect = NSZeroRect;
    for (Box *box in boxes) {
        rect = NSUnionRect(rect, [box rect]);
    }
    return rect;
}
-(void)dealloc {
    [boxes release];
    [super dealloc];
}
@end

int main (int argc, const char * argv[]) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *topLevelObjects;
    
    NSString *nibFile = @"file:///Users/david/Library/Developer/Xcode/DerivedData/LTWToolkit-ewrgnwzwitofwpcgqktuanpsxjpr/Build/Products/Debug/LTWAssessmentTool.app/Contents/Resources/NibTranslatorTest.nib";
    NSNib *nib = [[NSNib alloc] initWithContentsOfURL:[NSURL URLWithString:nibFile]];
    
    NSMutableArray *boxes = [NSMutableArray array];
    
    [nib instantiateNibWithOwner:[[DummyDelegate alloc] init] topLevelObjects:&topLevelObjects];
    
    for (id object in topLevelObjects) {
        if ([object isKindOfClass:[NSWindow class]]) {
            for (NSView *view in [[(NSWindow*)object contentView] subviews]) {
                [boxes addObject:[[ViewBox alloc] initWithView:view]];
            }
        }
    }
    
    BOOL changed;
    do {
        changed = NO;
        for (Box *box in boxes) {
            BoxBox *newBox = [[BoxBox alloc] init];
            newBox = [newBox boxByTryingToAddChildBox:box];
            for (Box *box2 in boxes) {
                if (box != box2) newBox = [newBox boxByTryingToAddChildBox:box2];
            }
            
            if ([newBox type] != UNKNOWN) {
                [boxes addObject:newBox];
                for (Box *boxToRemove in [newBox boxes]) {
                    [boxes removeObject:boxToRemove];
                }
                changed = YES;
                break;
            }
        }
    } while (changed);
    
    printXMLStart(stdout);
    
    for (Box *box in boxes) {
        [box printXMLTo:stdout depth:2 parent:nil];
    }
    
    printXMLEnd(stdout);
    
    
    [pool drain];
    return 0;
}

