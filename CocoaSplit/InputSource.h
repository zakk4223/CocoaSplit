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
#import "InputPopupControllerViewController.h"
#import "CSCaptureSourceProtocol.h"
#import "CSPluginLoader.h"



typedef enum input_rotate_style_t {
    
    kRotateNormal = 0,
    kRotateRandom = 1,
    kRotateReverse = 2
    
} input_rotate_style;


//@protocol CSCaptureSessionProtocol;

@interface InputSource : NSObject <NSCoding>
{
    CVPixelBufferRef _tmpCVBuf;
    CGColorSpaceRef _colorSpace;
    float _scale_x_pos, _scale_y_pos;
    float _internalScaleFactor;
    int _currentSourceIdx;
    CIImage *_oldImage;
    CIImage *_preBgImage;
    
    CVPixelBufferRef _oldCVBuf;
    
    double _transitionTime;
    bool _inTransition;
    double _nextImageTime;
    CIFilterGenerator *_filterGenerator;
    NSViewController *_currentInputViewController;
    
}



@property (strong) NSObject<CSCaptureSourceProtocol> *videoInput;
@property (assign) float x_pos;
@property (assign) float y_pos;
@property (assign) float rotationAngle;
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
@property (strong) CIFilter *chromaKeyFilter;

@property (strong) CIContext *imageContext;
@property (assign) NSSize oldSize;
@property (assign) bool active;

@property (assign) size_t display_width;
@property (assign) size_t display_height;

@property (assign) bool lockSize;

//When an instance is created the creator (capture controller) binds these to the size of the canvas in case we are asked to auto-fit
//at a later time

@property (assign) size_t canvas_width;
@property (assign) size_t canvas_height;

@property (strong) NSMutableArray *videoSources;

@property (assign) float changeInterval;

@property (strong) NSString *transitionFilterName;
@property (strong) NSArray *transitionNames;

@property (strong) InputPopupControllerViewController *windowViewController;

@property (assign) input_rotate_style rotateStyle;

@property (strong) CIFilter *transitionFilter;

@property (strong) NSArray *availableEffectNames;

@property (strong) NSMutableArray *currentEffects;

@property (strong) CIFilter *userFilter;

@property (strong) NSColor *chromaKeyColor;
@property (assign) float chromaKeyThreshold;
@property (assign) float chromaKeySmoothing;
@property (assign) bool doChromaKey;







@property (strong) NSPopover *editorPopover;


-(CIImage *) currentImage:(CIImage *)backgroundImage;
-(void) updateOrigin:(CGFloat)x y:(CGFloat)y;
-(void) frameRendered;
-(void) scaleTo:(CGFloat)width height:(CGFloat)height;
-(void) updateSize:(CGFloat)width height:(CGFloat)height;

-(void) addMulti;
-(void) autoFit;
-(void)addUserEffect:(NSIndexSet *)filterIndexes;
-(void)removeUserEffects:(NSIndexSet *)filterIndexes;
-(void)sourceConfigurationView;





@end
