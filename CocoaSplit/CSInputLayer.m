//
//  CSInputLayer.m
//  CocoaSplit
//
//  Created by Zakk on 1/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSInputLayer.h"
#import "CSCaptureBase.h"

@implementation CSInputLayer


@synthesize sourceLayer = _sourceLayer;
@synthesize allowResize = _allowResize;
@synthesize scrollXSpeed = _scrollXSpeed;
@synthesize scrollYSpeed = _scrollYSpeed;



-(instancetype)init
{
    if (self = [super init])
    {
        
        self.minificationFilter = kCAFilterTrilinear;
        self.magnificationFilter = kCAFilterTrilinear;
        _xLayer = [CAReplicatorLayer layer];
        _yLayer = [CAReplicatorLayer layer];
        _xLayer.instanceCount = 1;
        _yLayer.instanceCount = 1;
        
        _allowResize = YES;
        _sourceLayer = [CALayer layer];
        _sourceLayer.anchorPoint = CGPointMake(0.0, 0.0);
        //_sourceLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        _sourceLayer.contentsGravity = kCAGravityResizeAspect;
        _sourceLayer.frame = CGRectMake(0, 0, 1, 1);
        _scrollAnimation = [CABasicAnimation animation];
        _scrollAnimation.repeatCount = HUGE_VALF;
        self.backgroundColor = CGColorCreateGenericRGB(0, 0, 1, 1);
        self.zPosition = 0;
        
        [CSCaptureBase layoutModification:^{
            [_xLayer addSublayer:_sourceLayer];
            [_yLayer addSublayer:_xLayer];
            [self addSublayer:_yLayer];

        }];

    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.sublayers = nil;
        [CSCaptureBase layoutModification:^{
            [self addSublayer:_yLayer];
        }];

    }
    
    return self;
}


-(void)setScrollXSpeed:(float)scrollXSpeed
{
    if (scrollXSpeed == 0)
    {
        _xLayer.instanceCount = 1;
        [_yLayer removeAnimationForKey:@"position.x"];
        
    } else {
        _xLayer.instanceCount = 2;
        [self setupXAnimation:scrollXSpeed];
    }
    _scrollXSpeed = scrollXSpeed;
    
}

-(float)scrollXSpeed
{
    return _scrollXSpeed;
}

-(void)setScrollYSpeed:(float)scrollYSpeed
{
    if (scrollYSpeed == 0)
    {
        _yLayer.instanceCount = 1;
        [_yLayer removeAnimationForKey:@"position.y"];
        
    } else {
        _yLayer.instanceCount = 2;
        
        [self setupYAnimation:scrollYSpeed];
    }
    _scrollYSpeed = scrollYSpeed;
    
}

-(float)scrollYSpeed
{
    return _scrollYSpeed;
}


-(void)setupYAnimation:(float)speed
{
    if (speed == 0.0f)
    {
        return;
    }
    _scrollAnimation.keyPath = @"position.y";

    if (speed > 0)
    {
        _scrollAnimation.fromValue = @0.0;
        _scrollAnimation.toValue = [NSNumber numberWithFloat:-self.sourceLayer.bounds.size.height];
        _yLayer.instanceTransform = CATransform3DMakeTranslation(0,self.sourceLayer.bounds.size.height, 0);

        
    } else {
        _scrollAnimation.fromValue = @0.0;
        _scrollAnimation.toValue = [NSNumber numberWithFloat:self.sourceLayer.bounds.size.height];
        _yLayer.instanceTransform = CATransform3DMakeTranslation(0,-self.sourceLayer.bounds.size.height, 0);

    }
    
    _scrollAnimation.duration = fabs(speed);
    [_yLayer addAnimation:_scrollAnimation forKey:@"position.y"];

}

-(void)setupXAnimation:(float)speed
{
    
    if (speed == 0.0f)
    {
        return;
    }

    _scrollAnimation.keyPath = @"position.x";

    if (speed > 0)
    {
        _scrollAnimation.fromValue = @0.0;
        _scrollAnimation.toValue = [NSNumber numberWithFloat:-self.sourceLayer.bounds.size.width];
        _xLayer.instanceTransform = CATransform3DMakeTranslation(self.sourceLayer.bounds.size.width,0, 0);

        
    } else {
        _scrollAnimation.fromValue = @0.0;
        _scrollAnimation.toValue = [NSNumber numberWithFloat:self.sourceLayer.bounds.size.width];
        _xLayer.instanceTransform = CATransform3DMakeTranslation(-self.sourceLayer.bounds.size.width,0, 0);

    }
    
    _scrollAnimation.duration = fabs(speed);
    [_yLayer addAnimation:_scrollAnimation forKey:@"position.x"];
    
}

-(bool)allowResize
{
    return _allowResize;
}

-(void)setAllowResize:(bool)allowResize
{
    if (allowResize)
    {
        self.sourceLayer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable;
    } else {
        self.sourceLayer.autoresizingMask = kCALayerNotSizable;
    }
    
    _allowResize = allowResize;
}


-(CALayer *)sourceLayer
{
    return _sourceLayer;
}

-(void)copySourceSettings:(CALayer *)toLayer
{
    toLayer.anchorPoint = _sourceLayer.anchorPoint;//CGPointMake(0.0, 0.0);
    toLayer.filters = _sourceLayer.filters;
    toLayer.contentsGravity = _sourceLayer.contentsGravity;
    toLayer.contentsRect = _sourceLayer.contentsRect;
    toLayer.autoresizingMask = _sourceLayer.autoresizingMask;
    if (self.allowResize)
    {
        toLayer.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    }

}

-(void)setSourceLayer:(CALayer *)sourceLayer withTransition:(CATransition *)transition
{
    
    if (sourceLayer == _sourceLayer)
    {
        return;
    }
    
    
    [self copySourceSettings:sourceLayer];
    

    [CATransaction begin];
    CALayer *saveLayer = _sourceLayer;
    
    [CATransaction setCompletionBlock:^{
        [CATransaction begin];
        [saveLayer removeFromSuperlayer];
        [saveLayer removeAnimationForKey:kCATransition];
        [_sourceLayer removeAnimationForKey:kCATransition];
        [CATransaction commit];
    }];
    _sourceLayer.hidden = YES;
    [_sourceLayer.superlayer addSublayer:sourceLayer];
    sourceLayer.hidden = NO;
    

    [sourceLayer addAnimation:transition forKey:kCATransition];
    [_sourceLayer addAnimation:transition forKey:kCATransition];
    

    [CATransaction commit];
    _sourceLayer = sourceLayer;
    
    [self setupXAnimation:_scrollXSpeed];
    [self setupYAnimation:_scrollYSpeed];
}


-(void)setSourceLayer:(CALayer *)sourceLayer
{
    
    self.backgroundColor = NULL;

    [self copySourceSettings:sourceLayer];
    
    [_sourceLayer.superlayer replaceSublayer:_sourceLayer with:sourceLayer];
    
    _sourceLayer = sourceLayer;

    [self setupXAnimation:_scrollXSpeed];
    [self setupYAnimation:_scrollYSpeed];
}

-(void)setFrame:(CGRect)frame
{
    
    CGRect oldFrame = self.frame;
    
    [self resizeSourceLayer:frame oldFrame:oldFrame];
    [super setFrame:frame];
    
}



-(void)resizeSourceLayer:(CGRect)newFrame oldFrame:(CGRect)oldFrame
{
    

    
    if (self.allowResize)
    {
        if (CGSizeEqualToSize(_sourceLayer.frame.size, CGSizeZero) || CGSizeEqualToSize(oldFrame.size, CGSizeZero))
        {
            _sourceLayer.frame = newFrame;
        } else if (!CGSizeEqualToSize(oldFrame.size, newFrame.size)) {
            CGRect oldSourceFrame = _sourceLayer.frame;
            CGFloat scaleFactorX = oldSourceFrame.size.width / oldFrame.size.width;
            CGFloat scaleFactorY = oldSourceFrame.size.height / oldFrame.size.height;
            
            CGRect newSourceFrame;
            newSourceFrame.size.width = newFrame.size.width * scaleFactorX;
            newSourceFrame.size.height = newFrame.size.height * scaleFactorY;
            newSourceFrame.origin.x = (oldSourceFrame.origin.x / oldSourceFrame.size.width) * newSourceFrame.size.width;
            newSourceFrame.origin.y = (oldSourceFrame.origin.y / oldSourceFrame.size.height) * newSourceFrame.size.height;            
            _sourceLayer.frame = newSourceFrame;
        }
        
    }

    if (_scrollXSpeed)
    {
        float baseval = newFrame.size.width > self.sourceLayer.bounds.size.width ? newFrame.size.width : self.sourceLayer.bounds.size.width;
        float xval = _scrollXSpeed < 0 ? -baseval : baseval;
        
        _xLayer.instanceTransform = CATransform3DMakeTranslation(xval, 0, 0);
        CABasicAnimation *sAnim = ((CABasicAnimation *)[_yLayer animationForKey:@"position.x"]).copy;
        
        sAnim.toValue = [NSNumber numberWithFloat:-xval];
        [_yLayer addAnimation:sAnim forKey:@"position.x"];
    }
    
    if (_scrollYSpeed)
    {
        float baseval = newFrame.size.height > self.sourceLayer.bounds.size.height ? newFrame.size.height : self.sourceLayer.bounds.size.height;
        float yval = _scrollYSpeed < 0 ? -baseval : baseval;

        
        _yLayer.instanceTransform = CATransform3DMakeTranslation(0, yval, 0);
        CABasicAnimation *sAnim = ((CABasicAnimation *)[_yLayer animationForKey:@"position.y"]).copy;
        
        sAnim.toValue = [NSNumber numberWithFloat:-yval];
        [_yLayer addAnimation:sAnim forKey:@"position.y"];
        
    }

}

-(BOOL)containsPoint:(CGPoint)p
{
    if (self.hidden)
    {
        return NO;
    } else {
        return [super containsPoint:p];
    }
}


- (CALayer *)hitTest:(CGPoint)hitPoint
{
    
        
    hitPoint = [self convertPoint:hitPoint fromLayer:self.superlayer];
    return [self containsPoint:hitPoint] ? self : nil;
}

@end
