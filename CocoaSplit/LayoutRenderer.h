//
//  LayoutRenderer.h
//  CocoaSplit
//
//  Created by Zakk on 2/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"

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



@interface LayoutRenderer : NSObject <CALayerDelegate>
{
    CVPixelBufferPoolRef _cvpool;
    CVMetalTextureCacheRef _cvmetalcache;
    
    CVPixelBufferRef _currentPB;
    NSSize _cvpool_size;
    GLuint _fboTexture;
    GLuint _rFbo;
    CALayer *_currentLayoutlayer;
    bool _layoutChanged;
    CATransition *_layoutTransition;
    SourceLayout *_currentLayout;
    SourceLayout *_transitionLayout;
    bool _useMetalRenderer;
    id <MTLDevice> _metalDevice;
    
}

@property (strong) SourceLayout *layout;
@property (assign) CGLContextObj cglCtx;
@property (strong) CARenderer *renderer;
@property (strong) CALayer *rootLayer;
@property (strong) NSString *transitionName;
@property (strong) NSString *transitionDirection;
@property (strong) CIFilter *transitionFilter;

@property (assign) float transitionDuration;


-(CVPixelBufferRef)currentFrame;
-(CVPixelBufferRef)currentImg;


@end
