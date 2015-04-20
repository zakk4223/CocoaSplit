//
//  CSInputLayer.h
//  CocoaSplit
//
//  Created by Zakk on 1/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class InputSource;

@interface CSInputLayer : CALayer
{
    //CAReplicatorLayer *_xLayer;
    CAReplicatorLayer *_yLayer;
    
    CABasicAnimation *_scrollAnimation;
    CAConstraintLayoutManager *_realLayoutManager;
}


@property (strong) CALayer *sourceLayer;
@property (assign) bool allowResize;
@property (assign) float scrollXSpeed;
@property (assign) float scrollYSpeed;
@property (strong) CAReplicatorLayer *xLayer;
@property (assign) bool disableAnimation;
@property (assign) CGRect cropRect;
@property (assign) CGRect animateDummy;
@property (assign) bool is_animation_shadow;

@property (nonatomic, assign) CGFloat fakeWidth;
@property (nonatomic, assign) CGFloat fakeHeight;

-(void)setSourceLayer:(CALayer *)sourceLayer withTransition:(CATransition *)transition;
-(void)frameTick;
-(void)transitionToLayer:(CALayer *)toLayer fromLayer:(CALayer *)fromLayer withTransition:(CATransition *)transition;
-(void)transitionsDisabled;

@end
