//
//  CSOpenGLLayer.h
//  CocoaSplit
//
//  Created by Zakk on 2/20/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl.h>

@interface CSOpenGLLayer : CAOpenGLLayer
{
    CGRect _privateCropRect;
}


@property (assign) NSSize textureSize;


-(instancetype)initWithSize:(NSSize)size;

-(void)drawLayerContents:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts;


@end
