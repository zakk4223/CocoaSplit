//
//  CSAudioSwitchControl.m
//  CocoaSplit
//
//  Created by Zakk on 2/18/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSAudioSwitchControl.h"

@implementation CSAudioSwitchControl

-(void)mouseDown:(NSEvent *)theEvent
{

    NSInteger newSegment = !self.selectedSegment;
    switch (newSegment) {
        case 0:
            [self setLabel:@"On" forSegment:0];
            [self setLabel:@"" forSegment:1];
            break;
        case 1:
            [self setLabel:@"" forSegment:0];
            [self setLabel:@"Off" forSegment:1];
            break;
        default:
            break;
    }
    [self setSelectedSegment:!self.selectedSegment];
    [self sendAction:[self action] to:[self target]];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
