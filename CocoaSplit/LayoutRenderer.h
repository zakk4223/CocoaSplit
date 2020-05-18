//
//  LayoutRenderer.h
//  CocoaSplit
//
//  Created by Zakk on 2/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"
#import <Metal/Metal.h>

typedef struct CV_BRIDGED_TYPE(id) __CVMetalTextureCache *CVMetalTextureCacheRef;
typedef CVImageBufferRef CVMetalTextureRef;
CV_EXPORT CVReturn CVMetalTextureCacheCreateTextureFromImage(
                                                             CFAllocatorRef CV_NULLABLE allocator,
                                                             CVMetalTextureCacheRef CV_NONNULL textureCache,
                                                             CVImageBufferRef CV_NONNULL sourceImage,
                                                             CFDictionaryRef CV_NULLABLE textureAttributes,
                                                             MTLPixelFormat pixelFormat,
                                                             size_t width,
                                                             size_t height,
                                                             size_t planeIndex,
                                                             CV_RETURNS_RETAINED_PARAMETER CVMetalTextureRef CV_NULLABLE * CV_NONNULL textureOut ) API_AVAILABLE(macosx(10.11), ios(8.0), tvos(9.0)) __WATCHOS_PROHIBITED;
CV_EXPORT id <MTLTexture> CV_NULLABLE CVMetalTextureGetTexture( CVMetalTextureRef CV_NONNULL image ) API_AVAILABLE(macosx(10.11), ios(8.0), tvos(9.0)) __WATCHOS_PROHIBITED;
CV_EXPORT CVReturn CVMetalTextureCacheCreate(
                                             CFAllocatorRef CV_NULLABLE allocator,
                                             CFDictionaryRef CV_NULLABLE cacheAttributes,
                                             id <MTLDevice> CV_NONNULL metalDevice,
                                             CFDictionaryRef CV_NULLABLE textureAttributes,
                                             CV_RETURNS_RETAINED_PARAMETER CVMetalTextureCacheRef CV_NULLABLE * CV_NONNULL cacheOut ) API_AVAILABLE(macosx(10.11), ios(8.0), tvos(9.0)) __WATCHOS_PROHIBITED;



@interface LayoutRenderer : NSObject <CALayerDelegate>
{
    CVPixelBufferPoolRef _cvpool;
    CVMetalTextureCacheRef _cvmetalcache;
    CARemoteLayerServer *_caServer;
    CARemoteLayerClient *_caClient;
    CALayer *_remoteLayer;
    
    CVPixelBufferRef _currentPB;
    NSSize _cvpool_size;
    GLuint _fboTexture;
    GLuint _rFbo;
    bool _layoutChanged;
    SourceLayout *_currentLayout;
    bool _useMetalRenderer;
    id <MTLDevice> _metalDevice;
    id <MTLCommandQueue> _metalQueue;
    
    
}

@property (strong) SourceLayout * _Nonnull layout;
@property (assign) CGLContextObj _Nonnull cglCtx;
@property (strong) CARenderer * _Nonnull renderer;
@property (strong) CALayer * _Nullable rootLayer;

-(CVPixelBufferRef _Nullable)currentFrame;
-(CVPixelBufferRef _Nullable)currentImg;


@end
