//
//  CSShapeLayer.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/25/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CSShapePathLoader.h"


@class CSShapeWrapper;


@interface CSShapeLayer : CAShapeLayer
{
    CGAffineTransform _shapeTransform;
}

@property (strong)  CSShapeWrapper *shapeCreator;
@property (assign) bool flipX;
@property (assign) bool flipY;
@property (assign) CGFloat rotateAngle;

-(void)drawPath;

@end
