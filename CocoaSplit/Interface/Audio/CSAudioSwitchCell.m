//
//  CSAudioSwitchControl.m
//  CocoaSplit
//
//  Created by Zakk on 2/18/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSAudioSwitchCell.h"

@implementation CSAudioSwitchCell


-(NSBackgroundStyle)interiorBackgroundStyleForSegment:(NSInteger)segment
{
    return NSBackgroundStyleRaised;
}

/*
-(void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
    
    
    if (flag == YES)
    {
        
        [self setSelected:YES forSegment:!self.selectedSegment];
        [self send]
    }
}

*/


-(void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
    
    NSColor *color;
    
    
    if (self.selectedSegment == 0)
    {
        color = [NSColor greenColor];
    } else {
        color = [NSColor grayColor];
    }
    switch (segment) {
        case 0:
            if (self.selectedSegment == segment)
            {
                [self setLabel:@"On" forSegment:0];
            } else {
                [self setLabel:@"" forSegment:0];
            }
            break;
        case 1:
            if (self.selectedSegment == segment)
            {
                [self setLabel:@"Off" forSegment:1];
            } else {
                [self setLabel:@"" forSegment:1];
            }
            break;
        default:
            break;
    }
    if (color)
    {
        [color setFill];
        NSRectFill(frame);
    }
    
    [super drawSegment:segment inFrame:frame withView:controlView];
}
@end
