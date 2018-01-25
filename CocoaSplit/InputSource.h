//
//  InputSource.h
//  CocoaSplit
//
//  Created by Zakk on 7/17/14.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "Capture.h"
#import "CSCaptureSourceProtocolPrivate.h"
#import "CSPluginLoader.h"
#import "SourceCache.h"
#import "InputPopupControllerViewController.h"
#import "CSInputLayer.h"
#import "MIKMIDI.h"
#import "CSInputSourceProtocol.h"
#import "CSInputSourceBase.h"
#import "CSCaptureBaseInputFrameTickProtocol.h"

@interface InputSourcePrivateFrameUpdate : NSObject

@property (strong) void (^updateBlock)(CALayer *);
@property (strong) void (^postBlock)(void);


@end

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
    kResizeFree = 1<<5,
    kResizeCrop = 1<<6
} resize_style;



//@protocol CSCaptureSessionProtocol;

@protocol InputSourceExport <JSExport>
@property (strong) NSString *scriptStorage;


@property (assign) bool isMaskLayer;

@property (strong) NSString *compositingFilterName;


@property (assign) bool skipSave;

@property (assign) float scrollXSpeed;
@property (assign) float scrollYSpeed;

@property (strong) NSObject<CSCaptureSourceProtocolPrivate,CSCaptureBaseInputFrameTickProtocol> *videoInput;
@property (assign) float rotationAngle;
@property (assign) float rotationAngleY;
@property (assign) float rotationAngleX;
@property (assign) CGFloat crop_left;
@property (assign) CGFloat crop_right;
@property (assign) CGFloat crop_top;
@property (assign) CGFloat crop_bottom;

@property (assign) float opacity;

@property (assign) bool is_selected;
@property (assign) NSRect layoutPosition;

@property (assign) bool propertiesChanged;
@property (strong) NSString *selectedVideoType;


@property (assign) NSSize oldSize;
@property (assign) bool active;


@property (assign) bool lockSize;


@property (assign) bool unlock_aspect;

@property (assign) resize_style resizeType;

@property (readonly) NSPoint origin;
@property (readonly) NSSize size;
@property (readonly) float display_width;
@property (readonly) float display_height;
@property (assign) bool alwaysDisplay;
@property (assign) bool autoPlaceOnFrameUpdate;

@property (weak)     InputSource *clonedFromInput;

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
@property (assign) bool transitionEnabled;

@property (strong) id windowViewController;

@property (assign) input_rotate_style rotateStyle;

@property (strong) NSArray *availableEffectNames;

@property (strong) NSMutableArray *currentEffects;

@property (strong) CIFilter *userFilter;

@property (strong) NSColor *chromaKeyColor;
@property (assign) float chromaKeyThreshold;
@property (assign) float chromaKeySmoothing;
@property (assign) bool doChromaKey;

@property (strong) InputPopupControllerViewController *editorController;
@property (strong) NSWindow *editorWindow;

@property (strong) NSColor *borderColor;
@property (assign) CGFloat borderWidth;
@property (assign) CGFloat cornerRadius;
@property (strong) NSColor *backgroundColor;
@property (readonly) CGRect globalLayoutPosition;

@property (assign) float x_pos;
@property (assign) float y_pos;
@property (assign) float width;
@property (assign) float height;

@property (strong) NSMutableDictionary *constraintMap;

@property (strong) CIFilter *advancedTransition;
@property (strong) NSString *advancedTransitionName;

@property (strong) NSColor *startColor;
@property (strong) NSColor *stopColor;
@property (assign) CGFloat gradientStartX;
@property (assign) CGFloat gradientStartY;
@property (assign) CGFloat gradientStopX;
@property (assign) CGFloat gradientStopY;

@property (assign) CGFloat topLevelWidth;
@property (assign) CGFloat topLevelHeight;
@property (assign) bool needsAdjustment;
@property (assign) bool needsAdjustPosition;
@property (assign) bool isFrozen;
@property (assign) int frameDelay;


-(void) updateOrigin:(CGFloat)x y:(CGFloat)y;
-(void) positionOrigin:(CGFloat)x y:(CGFloat)y;

-(void) updateSize:(CGFloat)width height:(CGFloat)height;

-(void) autoFit;
-(void)addUserEffect:(NSIndexSet *)filterIndexes;
-(void)removeUserEffects:(NSIndexSet *)filterIndexes;
-(void)editorPopoverDidClose;
-(void)frameTick;
-(void)willDelete;
-(void)clearBackground;
-(CSInputLayer *)animationLayer;
-(void)makeSublayerOfLayer:(CALayer *)parentLayer;
-(void)detachAllInputs;
-(void)detachInput:(NSObject<CSInputSourceProtocol> *)toDetach;
-(void)attachInput:(NSObject<CSInputSourceProtocol> *)toAttach;
-(void)resetConstraints;
-(NSViewController *)sourceConfigurationView;
-(NSString *)addLayerFilter:(NSString *)filterName;
-(NSString *)addSourceFilter:(NSString *)filterName;
-(NSString *)addBackgroundFilter:(NSString *)filterName;
-(void)deleteLayerFilter:(NSString *)filteruuid;
-(void)deleteSourceFilter:(NSString *)filteruuid;
-(void)deleteBackgroundFilter:(NSString *)filteruuid;
-(void)buildLayerConstraints;
-(void)restoreConstraints;
-(void)createUUID;
-(void)updateRotationTransform;
-(void) directSize:(CGFloat)width height:(CGFloat)height;
-(void)addedToLayout;
-(void)autoCenter:(NSRect)containerRect;
-(void)autoCenter;
-(void)autoSize;
-(void)layerUpdated;
-(void)resetAspectRatio;
@end


@interface InputSource : CSInputSourceBase <CSInputSourceProtocol, InputSourceExport, NSCoding, NSWindowDelegate, NSCopying, MIKMIDIMappableResponder, MIKMIDIResponder>
{
    
    
    bool _alwaysDisplay;

    float _transitionDuration;
    NSString *_transitionDirection;
    input_rotate_style _rotateStyle;
    float _changeInterval;
    
    int _currentSourceIdx;
    
    CATransition *_multiTransition;
    
    double _transitionTime;
    double _nextImageTime;
    CIFilterGenerator *_filterGenerator;
    NSViewController *_currentInputViewController;
    CIFilter *_chromaFilter;
    __weak InputSource *_currentInput;

    int _frameCount;
    
    bool _encodingForCompare;
    
    
    
    CALayer *_currentLayer;
    
    bool _userBackground;
    
    NSDictionary *_constraintAttributeMap;
    NSArray *_constraintObserveKeys;
    NSMutableDictionary *_restoredConstraintMap;
    NSString *_editedName;
    NSDictionary *_undoActionMap;
    float _croppedAR;
    NSMutableArray *_frameUpdateQueue;
    
    
    
    
    
}

-(void)updateLayersWithNewFrame:(void (^)(CALayer *))updateBlock withPreuseBlock:(void(^)(void))preUseBlock withPostuseBlock:(void(^)(void))postUseBlock;

-(void)updateLayer:(void (^)(CALayer *layer))updateBlock;


-(void) setDirectVideoInput:(NSObject <CSCaptureSourceProtocolPrivate> *)videoInput;

-(NSViewController *)configurationViewController;

@property (strong) NSString *scriptStorage;


@property (assign) bool isMaskLayer;

@property (strong) NSString *compositingFilterName;


@property (assign) bool skipSave;

@property (assign) float scrollXSpeed;
@property (assign) float scrollYSpeed;

@property (strong) NSObject<CSCaptureSourceProtocolPrivate,CSCaptureBaseInputFrameTickProtocol> *videoInput;
@property (assign) float rotationAngle;
@property (assign) float rotationAngleY;
@property (assign) float rotationAngleX;
@property (assign) CGFloat crop_left;
@property (assign) CGFloat crop_right;
@property (assign) CGFloat crop_top;
@property (assign) CGFloat crop_bottom;

@property (assign) float opacity;

@property (assign) bool is_live;
@property (assign) bool is_selected;
@property (assign) NSRect layoutPosition;

@property (assign) bool propertiesChanged;
@property (strong) NSString *selectedVideoType;
@property (strong) NSString *name;


@property (assign) NSSize oldSize;
@property (assign) bool active;


@property (assign) bool lockSize;


@property (assign) bool unlock_aspect;

@property (assign) resize_style resizeType;

@property (readonly) NSPoint origin;
@property (readonly) NSSize size;
@property (readonly) float display_width;
@property (readonly) float display_height;
@property (assign) bool alwaysDisplay;
@property (assign) bool autoPlaceOnFrameUpdate;

@property (weak)     InputSource *clonedFromInput;

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
@property (assign) bool transitionEnabled;

@property (strong) id windowViewController;

@property (assign) input_rotate_style rotateStyle;

@property (strong) NSArray *availableEffectNames;

@property (strong) NSMutableArray *currentEffects;

@property (strong) CIFilter *userFilter;

@property (strong) NSColor *chromaKeyColor;
@property (assign) float chromaKeyThreshold;
@property (assign) float chromaKeySmoothing;
@property (assign) bool doChromaKey;

@property (strong) InputPopupControllerViewController *editorController;
@property (strong) NSWindow *editorWindow;

@property (strong) NSColor *borderColor;
@property (assign) CGFloat borderWidth;
@property (assign) CGFloat cornerRadius;
@property (strong) NSColor *backgroundColor;
@property (readonly) CGRect globalLayoutPosition;
@property (weak) InputSource* parentInput;

@property (assign) float x_pos;
@property (assign) float y_pos;
@property (assign) float width;
@property (assign) float height;

@property (strong) NSMutableDictionary *constraintMap;

@property (strong) CIFilter *advancedTransition;
@property (strong) NSString *advancedTransitionName;

@property (strong) NSColor *startColor;
@property (strong) NSColor *stopColor;
@property (assign) CGFloat gradientStartX;
@property (assign) CGFloat gradientStartY;
@property (assign) CGFloat gradientStopX;
@property (assign) CGFloat gradientStopY;

@property (assign) CGFloat topLevelWidth;
@property (assign) CGFloat topLevelHeight;
@property (assign) bool needsAdjustment;
@property (assign) bool needsAdjustPosition;
@property (assign) bool isFrozen;
@property (assign) int frameDelay;


@end
