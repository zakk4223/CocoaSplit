//
//  CSPreviewOverlayView.m
//  CocoaSplit
//
//  Created by Zakk on 8/31/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSPreviewOverlayView.h"
#import "PreviewView.h"

//wtf apple

@interface NSCursor (CSApplePrivate)
+ (instancetype)_bottomLeftResizeCursor;
+ (instancetype)_topLeftResizeCursor;
+ (instancetype)_bottomRightResizeCursor;
+ (instancetype)_topRightResizeCursor;
+ (instancetype)_windowResizeNorthEastSouthWestCursor;
+ (instancetype)_windowResizeNorthWestSouthEastCursor;
@end


@implementation CSPreviewOverlayView
@synthesize parentSource = _parentSource;


#define RESIZE_HANDLE_SIZE 6.0f


-(instancetype) init
{
    if (self = [super init])
    {
        self.renderControls = YES;
    }
    
    return self;
}


-(BOOL)wantsDefaultClipping
{
    return NO;
}


-(NSRect)insetSelectionRect
{
    return NSInsetRect(self.bounds, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}


-(NSRect)bottomLeftResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x-RESIZE_HANDLE_SIZE/2, insetRect.origin.y-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}


-(NSRect)bottomRightResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x+insetRect.size.width-RESIZE_HANDLE_SIZE/2, insetRect.origin.y-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}


-(NSRect)topRightResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x+insetRect.size.width-RESIZE_HANDLE_SIZE/2, insetRect.origin.y+insetRect.size.height-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}

-(NSRect)topLeftResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x-RESIZE_HANDLE_SIZE/2, insetRect.origin.y+insetRect.size.height-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}

-(NSRect)topResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(NSMidX(insetRect)-RESIZE_HANDLE_SIZE/2, insetRect.origin.y+insetRect.size.height-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}

-(NSRect)bottomResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(NSMidX(insetRect)-RESIZE_HANDLE_SIZE/2, insetRect.origin.y-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}

-(NSRect)leftResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x-5.0f, NSMidY(insetRect)-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}

-(NSRect)rightResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x+insetRect.size.width-RESIZE_HANDLE_SIZE/2, NSMidY(insetRect)-RESIZE_HANDLE_SIZE/2, RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetLineWidth( currentContext, 2.0 );
    CGContextSetStrokeColorWithColor(currentContext, [[NSColor blueColor] CGColor]);
    CGContextStrokeRect(currentContext, [self insetSelectionRect]);

    if (self.renderControls && self.parentSource && self.previewView)
    {
        CGContextSetFillColorWithColor(currentContext, [NSColor knobColor].CGColor);
        CGContextFillRect(currentContext, [self bottomLeftResizeRect]);
        CGContextFillRect(currentContext, [self bottomRightResizeRect]);
        CGContextFillRect(currentContext, [self topRightResizeRect]);
        CGContextFillRect(currentContext, [self topLeftResizeRect]);
/*
        CGContextFillEllipseInRect(currentContext, [self bottomLeftResizeRect]);
        CGContextFillEllipseInRect(currentContext, [self bottomRightResizeRect]);
        CGContextFillEllipseInRect(currentContext, [self topRightResizeRect]);
        CGContextFillEllipseInRect(currentContext, [self topLeftResizeRect]);
*/
        
        if (!_closeButton)
        {
            _closeButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:NSClosableWindowMask];
            [self addSubview:_closeButton];
            _closeButton.target = self;
            _closeButton.action = @selector(deleteSource);
        }
        
        if (!_autoFitButton)
        {
            _autoFitButton = [NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:NSClosableWindowMask];
            [self addSubview:_autoFitButton];
            _autoFitButton.target = self;
            _autoFitButton.action  = @selector(autoFitSource);
        }
        
        
        NSRect insetFrame = [self insetSelectionRect];
        
        NSRect bFrame = _closeButton.frame;
        bFrame.origin.x = insetFrame.origin.x+5;
        bFrame.origin.y = insetFrame.size.height - _closeButton.bounds.size.height/2 - 3;
        _closeButton.frame = bFrame;

        
        NSRect aFrame = _autoFitButton.frame;
        aFrame.origin.x = NSMaxX(bFrame)+5;
        aFrame.origin.y = bFrame.origin.y;
        _autoFitButton.frame = aFrame;
        
        
        if (insetFrame.size.width <= NSMaxX(_closeButton.frame) || _closeButton.frame.origin.y < RESIZE_HANDLE_SIZE)
        {
            _closeButton.hidden = YES;
        } else {
            _closeButton.hidden = NO;
        }

        
    }
    
    // Drawing code here.
}

-(void)autoFitSource
{
    if (self.parentSource && self.previewView)
    {
        [self.parentSource autoFit];
    }
}
-(void)deleteSource
{
    if (self.parentSource && self.previewView)
    {
        [self.previewView deleteInput:nil];
    }
}


-(BOOL)_mouseInGroup:(NSButton *)button
{
    return YES;
}


-(void)setParentSource:(InputSource *)parentSource
{
    _parentSource = parentSource;
    if (!parentSource)
    {
        [self removeFromSuperview];
    } else {
        NSRect myFrame = [self.previewView windowRectforWorldRect:parentSource.globalLayoutPosition];
        myFrame = NSInsetRect(myFrame, -RESIZE_HANDLE_SIZE, -RESIZE_HANDLE_SIZE);
        self.frame = myFrame;
        [self.previewView addSubview:self];
    }
}



-(InputSource *)parentSource
{
    return _parentSource;
}

-(void)updatePosition
{
    if (self.parentSource)
    {
        NSRect myFrame = [self.previewView windowRectforWorldRect:self.parentSource.globalLayoutPosition];
        myFrame = NSInsetRect(myFrame, -RESIZE_HANDLE_SIZE, -RESIZE_HANDLE_SIZE);
        self.frame = myFrame;
    }
}

-(BOOL)acceptsFirstResponder
{
    return NO;
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    NSLog(@"MOUSE ENTERED!!!");
}


@end


