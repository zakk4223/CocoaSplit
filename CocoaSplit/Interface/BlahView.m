//
//  BlahView.m
//  CocoaSplit
//
//  Created by Zakk on 1/2/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import "BlahView.h"

@implementation BlahView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (!self.blahColor)
    {
        [[NSColor redColor] setFill];
    } else {
        [self.blahColor setFill];
    }
    NSRectFill(dirtyRect);
    
    // Drawing code here.
}

@end
