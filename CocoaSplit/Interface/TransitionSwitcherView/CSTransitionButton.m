//
//  CSTransitionButton.m
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSTransitionButton.h"
#import "CSTransitionBase.h"
#import "CSTransitionCollectionItem.h"

@implementation CSTransitionButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
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
        [self.viewController transitionClicked];
    }
    
    self.mouseisDown = NO;
    [self setNeedsDisplay];
    
}


-(void)rightMouseDown:(NSEvent *)theEvent
{
    [self.viewController showTransitionMenu:theEvent];
}

-(BOOL)wantsUpdateLayer
{
    return YES;
}


-(void)updateLayer
{
    CGColorRef backgroundColor;
    CGFloat useAlpha = 1.0f;
    
    if (self.mouseisDown)
    {
        useAlpha = 0.3f;
    }
     CSTransitionBase *transition = self.viewController.representedObject;
    if (transition.active)
    {
        if (transition.isToggle)
        {
            backgroundColor = CGColorCreateGenericRGB(0.0f, 1.0f, 0.0f, useAlpha);
        } else {
            backgroundColor = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, useAlpha);
        }
    } else {
        backgroundColor = CGColorCreateGenericRGB(0.353f, 0.534f, 0.434, useAlpha);
    }
    self.layer.backgroundColor = backgroundColor;
    self.layer.cornerRadius = 5.0f;
}

@end
