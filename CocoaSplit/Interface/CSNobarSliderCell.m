//
//  CSNobarSliderCell.m
//  CocoaSplit
//
//  Created by Zakk on 8/13/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSNobarSliderCell.h"

@implementation CSNobarSliderCell

-(void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
    
    return;
}




-(void)drawmKnob:(NSRect)knobRect
{
    NSRect kRect = NSInsetRect(knobRect, knobRect.size.width/3, 2);
    //NSRect kRect = NSMakeRect(knobRect.origin.x + knobRect.size.width/3, knobRect.origin.y-5, knobRect.size.width/2, knobRect.size.height+5);
    NSBezierPath *knobPath = [NSBezierPath bezierPathWithRect:kRect];
    [NSColor.controlHighlightColor setFill];
    [NSColor.blackColor setStroke];
    [knobPath stroke];
    [knobPath fill];
    return;
}

@end
