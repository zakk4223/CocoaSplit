//
//  CSSyphonCaptureLayer.h
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 2/16/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SyphonBuildMacros.h"
#import "Syphon.h"

@interface CSSyphonCaptureLayer : CAOpenGLLayer
{
    CGLContextObj _myCGLContext;
    CGRect _lastBounds;
    CGSize _lastImageSize;
    CGRect _privateCropRect;
    CGRect _lastCrop;
    CGRect _calculatedCrop;
    bool _needsRedraw;
    
}


@property (strong) SyphonClient *syphonClient;
@property (assign) bool flipImage;

@end
