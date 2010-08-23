//
//  LTWOverlayTokensView.h
//  LTWToolkit
//
//  Created by David Alexander on 13/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef GTK_PLATFORM
#import <gtk/gtk.h>
#endif

#import "LTWTokens.h"

/*
 This class stores a rectangle that can be used to create overlays that appear on top of tokens in an LTWOverlayTokensView.
 The position of an LTWOverlayRect is based on the CURRENT position of the tokens that it was based on. An LTWOverlayRect can either be created directly from a sequence of tokens (in which case it is the bounding rect of those tokens), or as some function of existing LTWOverlayRects. (For example, it could be the centroid of a set of LTWOverlayRects.) If some tokens change their position, this will cause all LTWOverlayRects based on them -- and all LTWOverlayRects based on those, etc. -- to move as well. All of this will be animated.
 */
typedef enum {
    DIRECT_COCOA,
    DIRECT_GTK
} LTWOverlayRectType;
@interface LTWOverlayRect : NSObject {
    NSRect frame;
    
    LTWOverlayRectType rectType;
    
    // Used by DIRECT_* types:
    NSRange characterRange;
    
    // Used by DIRECT_COCOA type:
    NSTextView *textView; // We could store a pointer to the textView's textStorage here, but what if its address changed for some reason?
    
#ifdef GTK_PLATFORM
    // Used by DIRECT_GTK type:
    GtkTextView *gtkTextView;
#endif
}

-(id)initWithTextView:(NSTextView*)theTextView characterRange:(NSRange)theCharacterRange;
#ifdef GTK_PLATFORM
-(id)initWithGtkTextView:(GtkTextView*)theTextView characterRange:(NSRange)theCharacterRange gdkRect:(GdkRectangle)theRect;
#endif

@property (readonly) NSRect frame;

@end

/*
 Should LTWOverlayLayer also function as LTWOverlayRect?
 */
@interface LTWOverlayLayer : NSView {
    
}

@end

/*
 This is a text view that displays LTWTokens instances and also allows translucent overlays and animation.
 It should eventually be merged into LTWTokensView, or made a subclass of it. For the moment, however, I'd prefer to keep it separate as I think the @interface of LTWTokensView could use a bit of an overhaul.
 */
@interface LTWOverlayTokensView : NSTextView {
    LTWTokens *tokens;
    NSDictionary *nonXMLTokenRanges;
    NSMutableArray *overlayLayers;
}

-(void)setTokens:(LTWTokens*)theTokens;

-(LTWOverlayRect*)rectForTokensFromIndex:(NSUInteger)firstTokenIndex toIndex:(NSUInteger)lastTokenIndex;
-(void)addOverlayWithRect:(LTWOverlayRect*)overlayRect text:(NSString*)text; // NOTE: I'm not sure whether to have overlays added like this, or by calling a method on the overlay itself. Also, parameters other than "text" will probably be required.
-(void)collapseTokensFromIndex:(NSUInteger)firstTokenIndex toIndex:(NSUInteger)lastTokenIndex;

@end

@interface NSString (XMLEntityDecoding)
- (NSString *)stringByDecodingXMLEntities;
@end
