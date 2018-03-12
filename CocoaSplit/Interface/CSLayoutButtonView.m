//
//  CSLayoutButtonView.m
//  CocoaSplit
//
//  Created by Zakk on 3/4/18.
//

#import "CSLayoutButtonView.h"
#import "SourceLayout.h"
#import "CSLayoutCollectionItem.h"

@implementation CSLayoutButtonView

-(BOOL)wantsUpdateLayer
{
    return YES;
}

-(void)mouseDragged:(NSEvent *)event
{
    self.mouseisDown = NO;
    [self setNeedsDisplay];
    [[self nextResponder] mouseDown:event];
    [[self nextResponder] mouseDragged:event];
}


-(void)mouseDown:(NSEvent *)event
{
    self.mouseisDown = YES;

    [self setNeedsDisplay];
}

-(void)mouseUp:(NSEvent *)event
{
    if (self.mouseisDown)
    {
        [self.viewController layoutButtonPushed:self];
    }

    self.mouseisDown = NO;
    [self setNeedsDisplay];

}

-(void)mouseEntered:(NSEvent *)event
{
 
    
}
-(void)mouseExited:(NSEvent *)event
{
    self.mouseisDown = NO;
    self.viewController.upImage.hidden = YES;
    self.viewController.downImage.hidden = YES;
    [self setNeedsDisplay];
}

-(void)mouseMoved:(NSEvent *)event
{
    SourceLayout *myLayout = self.viewController.representedObject;
    NSPoint mouseLoc = [self convertPoint:event.locationInWindow fromView:nil];
    if (event.modifierFlags & NSShiftKeyMask && !(myLayout.in_live || myLayout.in_staging) )
    {
        if (mouseLoc.x < NSMidX(self.frame))
        {
            self.viewController.downImage.hidden = NO;
            self.viewController.upImage.hidden = YES;
        } else {
            self.viewController.downImage.hidden = YES;
            self.viewController.upImage.hidden = NO;
        }
    } else {
        self.viewController.upImage.hidden = YES;
        self.viewController.downImage.hidden = YES;
        
        
    }
}


-(void)rightMouseDown:(NSEvent *)theEvent
{
    [self.viewController showLayoutMenu:theEvent];
}


-(void)updateLayer
{
    CGColorRef backgroundColor;
    CGFloat useAlpha = 1.0f;
    
    
     if (self.mouseisDown)
     {
     useAlpha = 0.3f;
     }
    SourceLayout *myLayout = self.viewController.representedObject;

    if (myLayout.in_staging && myLayout.in_live)
    {
        backgroundColor = CGColorCreateGenericRGB(1.0f, 1.0f, 0.0f, useAlpha);
    } else if (myLayout.in_staging) {
        backgroundColor = CGColorCreateGenericRGB(0.0f, 1.0f, 0.0f, useAlpha);
    } else if (myLayout.in_live) {
        backgroundColor = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, useAlpha);
    } else {
        backgroundColor = CGColorCreateGenericRGB(0.353f, 0.534f, 0.434, useAlpha);
    }
    self.layer.backgroundColor = backgroundColor;
    self.layer.cornerRadius = 5.0f;
}

-(void)awakeFromNib
{
    
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseMoved) owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

@end
