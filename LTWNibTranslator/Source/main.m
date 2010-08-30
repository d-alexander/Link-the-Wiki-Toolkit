//
//  main.m
//  LTWNibTranslator
//
//  Created by David Alexander on 30/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface DummyDelegate : NSObject {
    
}
@end
@implementation DummyDelegate

@end

@interface Box : NSObject {
}
-(NSRect)rect;
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth;
@end
@implementation Box
-(NSRect)rect {
    return NSZeroRect;
}
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth {
}
@end

@interface ViewBox : Box {
    NSView *view;
}
@end
@implementation ViewBox
-(NSString*)description {
    return [NSString stringWithFormat:@"ViewBox { view = %@, rect = %@ }", view, NSStringFromRect([self rect])];
}
-(id)initWithView:(NSView*)theView {
    if (self = [super init]) {
        view = theView;
    }
    return self;
}
-(NSRect)rect {
    return [view frame];
}
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth {
    for (NSUInteger i=0; i<depth; i++) fprintf(file, "    ");
    fprintf(file, "<view type=\"%s\" />\n", [[[view class] description] UTF8String]);
}
@end
typedef enum {
    UNKNOWN, HORIZONTAL, VERTICAL
} BoxType;
@interface BoxBox : Box {
    NSMutableArray *boxes;
    BoxType type;
}
-(void)addBox:(Box*)theBox settingTypeTo:(BoxType)theType;
-(NSArray*)boxes;
-(BoxType)type;
@end
@implementation BoxBox
-(NSString*)description {
    return [NSString stringWithFormat:@"BoxBox { type = %@, rect = %@, boxes = %@ }", (type == UNKNOWN ? @"UNKNOWN" : type == HORIZONTAL ? @"HORIZONTAL" : @"VERTICAL"), NSStringFromRect([self rect]), boxes];
}
-(void)printXMLTo:(FILE*)file depth:(NSUInteger)depth {
    for (NSUInteger i=0; i<depth; i++) fprintf(file, "    ");
    fprintf(file, "<%cbox>\n", type == HORIZONTAL ? 'h' : 'v');
    
    for (Box *box in boxes) {
        [box printXMLTo:file depth:depth+1];
    }
    
    for (NSUInteger i=0; i<depth; i++) fprintf(file, "    ");
    fprintf(file, "</%cbox>\n", type == HORIZONTAL ? 'h' : 'v');
}
-(id)init {
    if (self = [super init]) {
        boxes = [[NSMutableArray alloc] init];
        type = UNKNOWN;
    }
    return self;
}
-(void)addBox:(Box*)theBox settingTypeTo:(BoxType)theType {
    NSAssert(type == UNKNOWN || type == theType, @"Tried to change the type of box %@.", self);
    type = theType;
    [boxes addObject:theBox];
}
-(void)tryAddingBox:(Box*)theBox {
    if (type == UNKNOWN && [boxes count] == 0) {
        [boxes addObject:theBox];
        return;
    }
    
    NSRect rect = [self rect];
    NSRect otherRect = [theBox rect];
    NSUInteger minXDiff = abs( NSMinX(rect) - NSMinX(otherRect) );
    NSUInteger minYDiff = abs( NSMinY(rect) - NSMinY(otherRect) );
    NSUInteger maxXDiff = abs( NSMaxX(rect) - NSMaxX(otherRect) );
    NSUInteger maxYDiff = abs( NSMaxY(rect) - NSMaxY(otherRect) );
    const NSUInteger tolerance = 10;
    
    if (type == UNKNOWN || type == HORIZONTAL) {
        if (minYDiff <= tolerance && maxYDiff <= tolerance) {
            type = HORIZONTAL;
            [boxes addObject:theBox];
        }
    }
    if (type == UNKNOWN || type == VERTICAL) {
        if (minXDiff <= tolerance && maxXDiff <= tolerance) {
            type = VERTICAL;
            [boxes addObject:theBox];
        }
    }
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
    
    BOOL changed = NO;
    do {
        changed = NO;
        for (Box *box in boxes) {
            BoxBox *newBox = [[BoxBox alloc] init];
            [newBox tryAddingBox:box];            
            for (Box *box2 in boxes) {
                if (box != box2) [newBox tryAddingBox:box2];
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
    
    for (Box *box in boxes) {
        [box printXMLTo:stdout depth:0];
    }
    
    
    [pool drain];
    return 0;
}

