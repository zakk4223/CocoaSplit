//
//  CSOverlayView.m
//  CocoaSplit
//
//  Created by Zakk on 8/25/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSOverlayView.h"


#define RESIZE_INSET 5.0f
@implementation CSOverlayView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
     }
    return self;
}

-(NSRect)insetSelectionRect
{
   return NSInsetRect(self.bounds, RESIZE_INSET, RESIZE_INSET);
}


-(NSRect)bottomLeftResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x-5.0f, insetRect.origin.y-5.0f, 10.0f, 10.0f);
}


-(NSRect)bottomRightResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x+insetRect.size.width-5.0f, insetRect.origin.y-5.0f, 10.0f, 10.0f);
}


-(NSRect)topRightResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x+insetRect.size.width-5.0f, insetRect.origin.y+insetRect.size.height-5.0f, 10.0f, 10.0f);
}

-(NSRect)topLeftResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x-5.0f, insetRect.origin.y+insetRect.size.height-5.0f, 10.0f, 10.0f);
}

-(NSRect)topResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(NSMidX(insetRect)-5.0f, insetRect.origin.y+insetRect.size.height-5.0f, 10.0f, 10.0f);
}

-(NSRect)bottomResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(NSMidX(insetRect)-5.0f, insetRect.origin.y-5.0f, 10.0f, 10.0f);
}

-(NSRect)leftResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x-5.0f, NSMidY(insetRect)-5.0f, 10.0f, 10.0f);
}

-(NSRect)rightResizeRect
{
    NSRect insetRect = [self insetSelectionRect];
    return NSMakeRect(insetRect.origin.x+insetRect.size.width-5.0f, NSMidY(insetRect)-5.0f, 10.0f, 10.0f);
}


-(window_resize_type)isResizing:(NSPoint)myPoint
{
    
    
    window_resize_type ret = kResizeNone;
    
    if (NSPointInRect(myPoint, [self rightResizeRect]))
        ret |= kResizeRight;
    if (NSPointInRect(myPoint, [self leftResizeRect]))
        ret |= kResizeLeft;
    if (NSPointInRect(myPoint, [self topResizeRect]))
        ret |= kResizeTop;
    if (NSPointInRect(myPoint, [self bottomResizeRect]))
        ret |= kResizeBottom;
    if (NSPointInRect(myPoint, [self bottomRightResizeRect]))
        ret |= kResizeBottom|kResizeRight;
    if (NSPointInRect(myPoint, [self topRightResizeRect]))
        ret |= kResizeRight|kResizeTop;
    if (NSPointInRect(myPoint, [self topLeftResizeRect]))
        ret |= kResizeTop|kResizeLeft;
    if (NSPointInRect(myPoint, [self bottomLeftResizeRect]))
        ret |= kResizeBottom|kResizeLeft;
    
    return ret;
}


- (void)drawRect:(NSRect)dirtyRect
{
    
    CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetLineWidth( currentContext, 2.0 );
    CGFloat dashLengths[] = { 5,3 };
    CGContextSetLineDash( currentContext, 0.0f, dashLengths, sizeof( dashLengths ) / sizeof( float ) );
    CGContextSetFillColorWithColor(currentContext, [NSColor colorWithDeviceRed:0.0f green:0.0f blue:1.0f alpha:0.2].CGColor);
    CGPathCreateWithRect(CGRectMake(2.0, 2.0, 100.0, 100.0), NULL);
    CGContextStrokeRect(currentContext, [self insetSelectionRect]);
    CGContextFillRect(currentContext, [self insetSelectionRect]);
    CGContextSetFillColorWithColor(currentContext, [NSColor blackColor].CGColor);
    CGContextFillEllipseInRect(currentContext, [self bottomLeftResizeRect]);
    CGContextFillEllipseInRect(currentContext, [self bottomRightResizeRect]);
    CGContextFillEllipseInRect(currentContext, [self topRightResizeRect]);
    CGContextFillEllipseInRect(currentContext, [self topLeftResizeRect]);
    CGContextFillEllipseInRect(currentContext, [self topResizeRect]);
    CGContextFillEllipseInRect(currentContext, [self bottomResizeRect]);
    CGContextFillEllipseInRect(currentContext, [self leftResizeRect]);
    CGContextFillEllipseInRect(currentContext, [self rightResizeRect]);
}


- (void)mouseDown:(NSEvent *)event
{
	NSPoint pointInView = [event locationInWindow];
	window_resize_type resizeType = [self isResizing:pointInView];
    
    
    
	NSWindow *window = self.window;
	NSPoint originalMouseLocation = [window convertBaseToScreen:[event locationInWindow]];
	
    while (YES)
	{
		//
		// Lock focus and take all the dragged and mouse up events until we
		// receive a mouse up.
		//
        NSEvent *newEvent = [window
                             nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		
        if ([newEvent type] == NSLeftMouseUp)
		{
			break;
		}
		
		//
		// Work out how much the mouse has moved
		//
		NSPoint newMouseLocation = [window convertBaseToScreen:[newEvent locationInWindow]];
		NSPoint delta = NSMakePoint(
                                    newMouseLocation.x - originalMouseLocation.x,
                                    newMouseLocation.y - originalMouseLocation.y);
		
		NSRect newFrame = [window frame];
		
        NSRect screenBounds = window.screen.frame;
        
        
		if (resizeType == kResizeNone)
		{
			newFrame.origin.x += delta.x;
			newFrame.origin.y += delta.y;
		}
		else
		{
            
            if (resizeType & kResizeRight)
            {
                if ((newFrame.origin.x + newFrame.size.width + delta.x) < screenBounds.origin.x+screenBounds.size.width+RESIZE_INSET)
                {
                    newFrame.size.width += delta.x;
                }
            }
            
            if (resizeType & kResizeTop)
            {
                if ((newFrame.origin.y + newFrame.size.height + delta.y) < screenBounds.origin.y+screenBounds.size.height+RESIZE_INSET)
                {
                    newFrame.size.height += delta.y;
                }

            }
            
            if (resizeType & kResizeBottom)
            {
                float newOriginY = newFrame.origin.y + delta.y;
                if (newOriginY > (screenBounds.origin.y-RESIZE_INSET))
                {
                    newFrame.size.height -= delta.y;
                    newFrame.origin.y = newOriginY;
                }
            }
            
            if (resizeType & kResizeLeft)
            {
                float newOriginX = newFrame.origin.x + delta.x;
                if (newOriginX > (screenBounds.origin.x-RESIZE_INSET))
                {
                    newFrame.size.width -= delta.x;
                    newFrame.origin.x = newOriginX;
                }
            }
		}

        if (newFrame.origin.x < screenBounds.origin.x - RESIZE_INSET)
        {
            newFrame.origin.x = screenBounds.origin.x - RESIZE_INSET;
        }
        
        if (newFrame.origin.y < screenBounds.origin.y - RESIZE_INSET)
        {
            newFrame.origin.y = screenBounds.origin.y - RESIZE_INSET;
        }
        
        
        if ((newFrame.origin.x + newFrame.size.width) > screenBounds.origin.x + NSWidth(screenBounds)+RESIZE_INSET)
        {
            newFrame.origin.x = screenBounds.origin.x + NSWidth(screenBounds) - newFrame.size.width + RESIZE_INSET;
        }
        
        if ((newFrame.origin.y + newFrame.size.height) > screenBounds.origin.y + NSWidth(screenBounds) + RESIZE_INSET)
        {
            newFrame.origin.y = screenBounds.origin.y + NSWidth(screenBounds) - newFrame.size.height + RESIZE_INSET;
        }

        
		[window setFrame:newFrame display:YES animate:NO];

        
        originalMouseLocation = newMouseLocation;
	}
    

}




@end
