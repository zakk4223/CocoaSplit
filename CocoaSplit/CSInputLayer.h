//
//  CSInputLayer.h
//  CocoaSplit
//
//  Created by Zakk on 1/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class InputSource;

@protocol CSInputLayerJSExport <JSExport>
@property (weak) InputSource *sourceInput;

@property (strong) CALayer *sourceLayer;
@property (assign) float scrollXSpeed;
@property (assign) float scrollYSpeed;
@property (strong) CAReplicatorLayer *xLayer;
@property (assign) bool disableAnimation;
@property (assign) CGRect cropRect;
@property (assign) CGRect animateDummy;
@property (assign) bool is_animation_shadow;

@property (nonatomic, assign) CGFloat fakeWidth;
@property (nonatomic, assign) CGFloat fakeHeight;


@property (strong) NSColor *startColor;
@property (strong) NSColor *stopColor;

@property (assign) CGFloat gradientStartX;
@property (assign) CGFloat gradientStartY;
@property (assign) CGFloat gradientStopX;
@property (assign) CGFloat gradientStopY;

-(void)frameTick;
-(void)transitionToLayer:(CALayer *)toLayer fromLayer:(CALayer *)fromLayer withTransition:(CATransition *)transition;
-(void)transitionsDisabled;
-(void)clearGradient;

@end

@interface CSInputLayer : CAGradientLayer <CSInputLayerJSExport,  CALayerDelegate, CALayoutManager>
{
    //CAReplicatorLayer *_xLayer;
    CAReplicatorLayer *_yLayer;
    
    CABasicAnimation *_scrollAnimation;
    CAConstraintLayoutManager *_realLayoutManager;
}


@property (weak) InputSource *sourceInput;

@property (strong) CALayer *sourceLayer;
@property (assign) float scrollXSpeed;
@property (assign) float scrollYSpeed;
@property (strong) CAReplicatorLayer *xLayer;
@property (assign) bool disableAnimation;
@property (assign) CGRect cropRect;
@property (assign) CGRect animateDummy;
@property (assign) bool is_animation_shadow;

@property (nonatomic, assign) CGFloat fakeWidth;
@property (nonatomic, assign) CGFloat fakeHeight;


@property (strong) NSColor *startColor;
@property (strong) NSColor *stopColor;

@property (assign) CGFloat gradientStartX;
@property (assign) CGFloat gradientStartY;
@property (assign) CGFloat gradientStopX;
@property (assign) CGFloat gradientStopY;




@end
