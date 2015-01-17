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
#import "CSInputLayer.h"



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
    kResizeLeft = 1<<3,
    kResizeCenter = 1<<4,
    kResizeFree = 1<<5
} resize_style;



//@protocol CSCaptureSessionProtocol;

@interface InputSource : NSObject <NSCoding, NSWindowDelegate>
{
    
    int _currentSourceIdx;
    
    CATransition *_multiTransition;
    
    double _transitionTime;
    double _nextImageTime;
    CIFilterGenerator *_filterGenerator;
    NSViewController *_currentInputViewController;
    CIFilter *_chromaFilter;
    NSObject<CSCaptureSourceProtocol> *_nextInput;

    
}


@property (strong) CSInputLayer *layer;
@property (weak) SourceLayout *layout;


@property (assign) float scrollXSpeed;
@property (assign) float scrollYSpeed;

@property (strong) NSObject<CSCaptureSourceProtocol> *videoInput;
@property (assign) float rotationAngle;
@property (assign) float crop_left;
@property (assign) float crop_right;
@property (assign) float crop_top;
@property (assign) float crop_bottom;

@property (assign) float opacity;

@property (assign) bool is_live;
@property (assign) bool is_selected;
@property (assign) NSRect layoutPosition;

@property (assign) bool propertiesChanged;
@property (strong) NSString *selectedVideoType;
@property (strong) NSString *name;
@property (strong) NSString *uuid;

@property (assign) float depth;

@property (assign) NSSize oldSize;
@property (assign) bool active;


@property (assign) bool lockSize;


@property (assign) bool unlock_aspect;

@property (assign) resize_style resizeType;

@property (readonly) NSPoint origin;
@property (readonly) NSSize size;
@property (readonly) float display_width;
@property (readonly) float display_height;


//When an instance is created the creator (capture controller) binds these to the size of the canvas in case we are asked to auto-fit
//at a later time

@property (readonly) size_t canvas_width;
@property (readonly) size_t canvas_height;

@property (strong) NSMutableArray *videoSources;

@property (assign) float changeInterval;

@property (strong) NSString *transitionFilterName;
@property (strong) NSArray *transitionNames;
@property (strong) NSArray *transitionDirections;
@property (strong) NSString *transitionDirection;
@property (assign) float transitionDuration;

@property (strong) id windowViewController;

@property (assign) input_rotate_style rotateStyle;

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


-(void) updateOrigin:(CGFloat)x y:(CGFloat)y;
-(void) updateSize:(CGFloat)width height:(CGFloat)height;

-(void) addMulti;
-(void) autoFit;
-(void)addUserEffect:(NSIndexSet *)filterIndexes;
-(void)removeUserEffects:(NSIndexSet *)filterIndexes;
-(void)editorPopoverDidClose;
-(void)frameTick;
-(void)willDelete;





@end
