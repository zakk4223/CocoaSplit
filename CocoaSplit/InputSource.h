//
//  InputSource.h
//  CocoaSplit
//
//  Created by Zakk on 7/17/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>
#import "Capture.h"






@protocol CaptureSessionProtocol;

@interface InputSource : NSObject <NSCoding>
{
    CVPixelBufferRef _tmpCVBuf;
    CGColorSpaceRef _colorSpace;
    
}

@property (strong) NSString *settingsTab;

@property (strong) id<CaptureSessionProtocol> videoInput;
@property (assign) float x_pos;
@property (assign) float y_pos;
@property (assign) double rotationAngle;
@property (assign) int crop_left;
@property (assign) int crop_right;
@property (assign) int crop_top;
@property (assign) int crop_bottom;
@property (assign) float scaleFactor;
@property (strong) CIImage *inputImage;
@property (strong) CIImage *outputImage;
@property (assign) float opacity;

@property (assign) bool is_selected;
@property (assign) NSRect layoutPosition;

@property (strong) CIFilter *scaleFilter;
@property (strong) CIFilter *selectedFilter;
@property (strong) CIFilter *transformFilter;


@property (assign) bool propertiesChanged;
@property (strong) CIFilter *compositeFilter;
@property (strong) NSString *selectedVideoType;
@property (strong) NSString *name;
@property (strong) NSString *uuid;

@property (assign) int depth;
@property (strong) CIFilter *solidFilter;
@property (strong) CIFilter *cropFilter;

@property (strong) CIContext *imageContext;
@property (assign) size_t source_width;
@property (assign) size_t source_height;
@property (strong) NSAffineTransform *currentTransform;
@property (assign) NSSize oldSize;


//When an instance is created the creator (capture controller) binds these to the size of the canvas in case we are asked to auto-fit
//at a later time

@property (assign) size_t canvas_width;
@property (assign) size_t canvas_height;

@property (strong) NSPopover *editorPopover;


-(CIImage *) currentImage:(CIImage *)backgroundImage;
-(void) updateOrigin:(CGFloat)x y:(CGFloat)y;
-(void) frameRendered;
-(void) scaleTo:(CGFloat)width height:(CGFloat)height;
-(void) autoFit;



@end
