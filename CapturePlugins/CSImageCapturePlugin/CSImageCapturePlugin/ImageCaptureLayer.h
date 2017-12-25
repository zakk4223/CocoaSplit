//
//  ImageCaptureLayer.h
//  CSImageCapturePlugin
//
//  Created by Zakk on 11/7/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface ImageCaptureLayer : CALayer

@property (assign) int gifIndex;
@property (assign) CGImageSourceRef sourceRef;

@end
