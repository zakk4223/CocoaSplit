//
//  CSShapeLayer.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/25/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSShapeLayer.h"

@implementation CSShapeLayer



-(void)drawPath
{
    
    
    
    if (self.pathModule && self.shapeLoader && !CGRectEqualToRect(self.frame, CGRectZero))
    {
        [self.shapeLoader setPathForLayer:self withPlugin:self.pathModule];
    }
}

-(void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
}
-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self drawPath];
}


@end
