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
#import "CSCaptureSourceProtocol.h"
#import "CSPluginLoader.h"
#import "SourceCache.h"
#import "InputPopupControllerViewController.h"



@class SourceLayout;

typedef enum input_rotate_style_t {
    
    kRotateNormal = 0,
    kRotateRandom = 1,
    kRotateReverse = 2
    
} input_rotate_style;

typedef enum resize_style_t {
    
    kResizeNone = 0,
    kResizeTop = 1 << 0,
    kResizeRight = 1<<1,
    kResizeBottom = 1<<2,
    kResizeLeft = 1<<3
    
} resize_style;



//@protocol CSCaptureSessionProtocol;

@interface InputSource : NSObject <NSCoding, NSWindowDelegate>
{
    CVPixelBufferRef _tmpCVBuf;
    CGColorSpaceRef _colorSpace;
    float _scale_x_pos, _scale_y_pos;
    float _internalScaleFactor;
    int _scale_width, _scale_height;
    
    int _currentSourceIdx;
    CIImage *_oldImage;
    CIImage *_preBgImage;
    
    CVPixelBufferRef _oldCVBuf;
    
    double _transitionTime;
    bool _inTransition;
    double _nextImageTime;
    CIFilterGenerator *_filterGenerator;
    NSViewController *_currentInputViewController;
    float _locked_ar;
    resize_style _last_resize;
    int _adjusted_x_pos;
    int _adjusted_y_pos;
    
    //NSObject<CSCaptureSourceProtocol> *_useInput;

    
}



@property (weak) SourceLayout *layout;

@property (strong) NSObject<CSCaptureSourceProtocol> *videoInput;
@property (assign) int x_pos;
@property (assign) int y_pos;
@property (assign) float rotationAngle;
@property (assign) int crop_left;
@property (assign) int crop_right;
@property (assign) int crop_top;
@property (assign) int crop_bottom;
@property (assign) float scaleFactor;
@property (strong) CIImage *inputImage;
@property (strong) CIImage *outputImage;
@property (assign) float opacity;

@property (assign) bool is_live;
@property (assign) bool is_selected;
@property (assign) NSRect layoutPosition;
@property (strong) CIFilter *scaleFilter;
@property (strong) CIFilter *prescaleTransformFilter;
@property (strong) CIFilter *postscaleTransformFilter;


@property (strong) CIFilter *selectedFilter;
@property (strong) CIFilter *transformFilter;
@property (strong) CIFilter *rotateFilter;



@property (assign) bool propertiesChanged;
@property (strong) CIFilter *compositeFilter;
@property (strong) NSString *selectedVideoType;
@property (strong) NSString *name;
@property (strong) NSString *uuid;

@property (assign) int depth;
@property (strong) CIFilter *solidFilter;
@property (strong) CIFilter *cropFilter;
@property (strong) CIFilter *chromaKeyFilter;

@property (weak) CIContext *imageContext;
@property (assign) NSSize oldSize;
@property (assign) bool active;

@property (assign) size_t display_width;
@property (assign) size_t display_height;

@property (assign) bool lockSize;

@property (assign) bool needRebuildFilter;

@property (assign) bool unlock_aspect;

@property (assign) resize_style resizeType;


//When an instance is created the creator (capture controller) binds these to the size of the canvas in case we are asked to auto-fit
//at a later time

@property (readonly) size_t canvas_width;
@property (readonly) size_t canvas_height;

@property (strong) NSMutableArray *videoSources;

@property (assign) float changeInterval;

@property (strong) NSString *transitionFilterName;
@property (strong) NSArray *transitionNames;

@property (strong) id windowViewController;

@property (assign) input_rotate_style rotateStyle;

@property (strong) CIFilter *transitionFilter;

@property (strong) NSArray *availableEffectNames;

@property (strong) NSMutableArray *currentEffects;

@property (strong) CIFilter *userFilter;

@property (strong) NSColor *chromaKeyColor;
@property (assign) float chromaKeyThreshold;
@property (assign) float chromaKeySmoothing;
@property (assign) bool doChromaKey;
@property (assign) bool usePrivateSource;







@property (strong) InputPopupControllerViewController *editorController;
@property (strong) NSWindow *editorWindow;


-(CIImage *) currentImage:(CIImage *)backgroundImage;
-(void) updateOrigin:(CGFloat)x y:(CGFloat)y;
-(void) frameRendered;
-(void) scaleTo:(CGFloat)width height:(CGFloat)height;
-(void) updateSize:(CGFloat)width height:(CGFloat)height;
-(NSRect) scaleToRect:(CGRect)rect extent:(CGRect)extent;

-(void) addMulti;
-(void) autoFit;
-(void)addUserEffect:(NSIndexSet *)filterIndexes;
-(void)removeUserEffects:(NSIndexSet *)filterIndexes;
-(void)editorPopoverDidClose;





@end
