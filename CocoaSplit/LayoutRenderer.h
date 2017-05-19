//
//  LayoutRenderer.h
//  CocoaSplit
//
//  Created by Zakk on 2/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"

@interface LayoutRenderer : NSObject
{
    CVPixelBufferPoolRef _cvpool;
    CVPixelBufferRef _currentPB;
    NSSize _cvpool_size;
    GLuint _fboTexture;
    GLuint _rFbo;
    CALayer *_currentLayoutlayer;
    bool _layoutChanged;
    CATransition *_layoutTransition;
    SourceLayout *_currentLayout;
    SourceLayout *_transitionLayout;
    
    
    
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
