//
//  CSShapeLayer.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/25/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSShapeLayer.h"
#import "CSShapeWrapper.h"

@implementation CSShapeLayer




-(void)transformPath
{
    
    CGAffineTransform useTransform = CGAffineTransformIdentity;
    
    if (self.flipX)
    {
        useTransform = CGAffineTransformTranslate(useTransform, self.frame.size.width, 0);
        useTransform = CGAffineTransformScale(useTransform, -1.0, 1.0);
    }
    
    if (self.flipY)
    {
        useTransform = CGAffineTransformTranslate(useTransform, 0, self.frame.size.height);
        useTransform = CGAffineTransformScale(useTransform, 1.0, -1.0);

    }
    
    if (self.rotateAngle)
    {
        useTransform = CGAffineTransformTranslate(useTransform, self.frame.size.width/2, self.frame.size.height/2);
        useTransform = CGAffineTransformRotate(useTransform, self.rotateAngle * M_PI / 180);
        useTransform = CGAffineTransformTranslate(useTransform, -self.frame.size.width/2, -self.frame.size.height/2);

        
    }
    
    
    self.path = CGPathCreateCopyByTransformingPath(self.path, &useTransform);

}

-(void)drawPath
{
    
    if (self.shapeCreator)
    {
        @try {
            [self.shapeCreator getcgpath:self.frame forLayer:self];
        }
        @catch (NSException *exception) {
            NSLog(@"Path creation for layer failed with exception %@", exception);
        }
        
        if (self.path)
        {
                        
            [self transformPath];
        }
    }
    
    return;
    
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self drawPath];
}


@end
