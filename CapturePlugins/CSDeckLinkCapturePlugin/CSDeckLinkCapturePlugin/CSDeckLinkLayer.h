//
//  CSDeckLinkLayer.h
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/14/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl.h>
#import "DeckLinkBridge.h"


@interface CSDeckLinkLayer : CAOpenGLLayer
{
    CGLContextObj _myCGLContext;
    CGRect _lastBounds;
    CGSize _lastImageSize;
    CGRect _privateCropRect;
    CGRect _lastCrop;
    CGRect _calculatedCrop;
    bool _needsRedraw;
    CFAbsoluteTime _lastDrawTime;
    CGSize _deckLinkFrameSize;
    
}



@property (assign)  IDeckLinkGLScreenPreviewHelper *deckLinkOGL;
-(void)setRenderFrame:(IDeckLinkVideoFrame *)frame;


@end
