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

-(void)mouseDown:(NSEvent *)event
{
    self.mouseisDown = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [self setNeedsDisplay];
}

-(void)mouseUp:(NSEvent *)event
{
    if (self.mouseisDown)
    {
        [self.viewController layoutButtonPushed:self];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.mouseisDown = NO;
    [self setNeedsDisplay];

}

-(void)mouseHovered
{
    [self.viewController layoutButtonHovered:self];
}


-(void)mouseEntered:(NSEvent *)event
{
    [self performSelector:@selector(mouseHovered) withObject:nil afterDelay:1.0];
}

-(void)mouseExited:(NSEvent *)event
{
    self.mouseisDown = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setNeedsDisplay];
}

-(void)rightMouseDown:(NSEvent *)theEvent
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

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
    int opts = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited);
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
}

@end
