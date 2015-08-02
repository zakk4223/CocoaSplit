//
//  CSShapeWrapper.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 8/2/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSShapeWrapper.h"

@implementation CSShapeWrapper
-(void)getcgpath:(NSRect)withFrame forLayer:(CSShapeLayer *)forLayer
{
    forLayer.path = CGPathCreateMutable();
}


@end
