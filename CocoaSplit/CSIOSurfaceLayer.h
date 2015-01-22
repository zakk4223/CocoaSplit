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
    CGRect _privateCropRect;
    CGRect _calculatedCrop;
    NSRect _lastSurfaceSize;
}

@property (assign) IOSurfaceRef ioSurface;
@property (atomic, strong) CIImage *ioImage;
@property (assign) CVImageBufferRef imageBuffer;
@property (assign) BOOL flipImage;
@property (weak) id frameSourceDelegate;
@end

