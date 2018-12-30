//
//  CSSnapOverlayView.m
//  CocoaSplit
//
//  Created by Zakk on 12/28/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import "CSSnapOverlayView.h"

@implementation CSSnapOverlayView

@synthesize drawLines = _drawLines;

-(instancetype) init
{
    if (self = [super init])
    {
        
    }
    
    return self;
}

-(void)setDrawLines:(NSArray *)drawLines
{
    _drawLines = drawLines;
    [self setNeedsDisplay:YES];
}

-(NSArray *)drawLines
{
    return _drawLines;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (self.drawLines && self.drawLines.count > 0)
    {
        CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextSetLineWidth(currentContext, 1.0);
        CGColorRef lineColor = CGColorCreateGenericRGB(1.0, 1.0, 0.0,1.0);
        CGContextSetStrokeColorWithColor(currentContext, lineColor);
        CGColorRelease(lineColor);
        for (NSValue *val in self.drawLines)
        {
            NSRect lineDef = [val rectValue];
            CGContextMoveToPoint(currentContext, lineDef.origin.x, lineDef.origin.y);
            CGContextAddLineToPoint(currentContext, NSMaxX(lineDef), NSMaxY(lineDef));
        }
        CGContextStrokePath(currentContext);

    }
}

@end
