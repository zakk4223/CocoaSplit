//
//  CSShapeCapture.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/24/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCaptureBase.h"
#import "CSAbstractCaptureDevice.h"
#import "CSShapePathLoader.h"
#import "CSShapeLayer.h"

@interface CSShapeCapture : CSCaptureBase <CSCaptureSourceProtocol>

+(CSShapePathLoader *) sharedPathLoader;

@property (strong) NSColor *fillColor;
@property (strong) NSColor *lineColor;
@property (assign) CGFloat lineWidth;
@property (strong) NSColor *backgroundColor;
@property (assign) bool flipX;
@property (assign) bool flipY;
@property (assign) CGFloat rotateAngle;



@end
