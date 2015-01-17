//
//  CSIOSurfaceLayer.h
//  CocoaSplit
//
//  Created by Zakk on 1/4/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CSIOSurfaceLayer : CAOpenGLLayer
{
    CIContext *_ciCtx;
}

@property (assign) IOSurfaceRef ioSurface;
@property (strong) CIImage *ioImage;
@property (assign) BOOL flipImage;

@end
