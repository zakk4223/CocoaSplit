//
//  CSOverlayView.m
//  CocoaSplit
//
//  Created by Zakk on 8/25/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSOverlayView.h"
#import <QuartzCore/QuartzCore.h>


#define RESIZE_INSET 0.0f
@implementation CSOverlayView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
     }
    return self;
}





- (void)drawRect:(NSRect)dirtyRect
{
    
    CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetLineWidth( currentContext, 2.0 );
    CGFloat dashLengths[] = { 5.0f, 3.0f };
    CGContextSetLineDash( currentContext, 0.0f, dashLengths, sizeof( dashLengths ) / sizeof( CGFloat ) );
    CGContextSetFillColorWithColor(currentContext, [NSColor colorWithDeviceRed:0.0f green:0.0f blue:1.0f alpha:0.2].CGColor);
    CGContextStrokeRect(currentContext, [self bounds]);
    CGContextFillRect(currentContext, [self bounds]);

}




@end
