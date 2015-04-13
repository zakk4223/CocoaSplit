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

@dynamic animateDummy;

@synthesize sourceLayer = _sourceLayer;
@synthesize scrollXSpeed = _scrollXSpeed;
@synthesize scrollYSpeed = _scrollYSpeed;
@synthesize cropRect = _cropRect;


-(void)layoutSublayersOfLayer:(CALayer *)layer
{
    [self layoutSublayers];
}


-(void)layoutSublayers
{
    
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if (self.allowResize)
    {
        _sourceLayer.bounds = self.bounds;
        _sourceLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;


    } else {
        
        //This is mostly for CATextLayer hax, but CALayer allows the setting for arbitrary keyvalues, so....
        
        _sourceLayer.autoresizingMask = kCALayerNotSizable;
        
        NSString *alignment = [_sourceLayer valueForKey:@"alignmentMode"];
        
        if ([alignment isEqualToString:kCAAlignmentRight])
        {
            
            _sourceLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

            float newX = NSMaxX(self.bounds)-_sourceLayer.bounds.size.width;
            
            _sourceLayer.position = CGPointMake(newX, 0);
        } else if ([alignment isEqualToString:kCAAlignmentCenter]) {
            float newX = NSMidX(self.bounds)-_sourceLayer.bounds.size.width/2;
            _sourceLayer.position = CGPointMake(newX, 0);
        } else {
            _sourceLayer.position = CGPointMake(0.0, 0.0);
        }
    }
    
    [self resizeSourceLayer:self.frame oldFrame:CGRectZero];
    [CATransaction commit];

    
}


-(instancetype)init
{
    if (self = [super init])
    {
        
        self.minificationFilter = kCAFilterTrilinear;
        self.magnificationFilter = kCAFilterTrilinear;
        self.disableAnimation = NO;
        
        
        _xLayer = [CAReplicatorLayer layer];
        _yLayer = [CAReplicatorLayer layer];
        _xLayer.instanceCount = 1;
        _yLayer.instanceCount = 1;
        
        _cropRect = CGRectZero;
        
        
        
        _allowResize = YES;
        _sourceLayer = [CALayer layer];
        _sourceLayer.anchorPoint = CGPointMake(0.0, 0.0);
        _sourceLayer.contentsGravity = kCAGravityResizeAspect;
        _sourceLayer.frame = CGRectMake(0, 0, 1, 1);
        _scrollAnimation = [CABasicAnimation animation];
        _scrollAnimation.repeatCount = HUGE_VALF;
        self.zPosition = 0;
        _xLayer.layoutManager = self;
        
        [_xLayer addSublayer:_sourceLayer];
        [_yLayer addSublayer:_xLayer];
        [self addSublayer:_yLayer];
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.sublayers = nil;
        [CSCaptureBase layoutModification:^{
            //[self addSublayer:_yLayer];
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


-(CALayer *)sourceLayer
{
    return _sourceLayer;
}


-(void)copySourceSettings:(CALayer *)toLayer
{
    toLayer.anchorPoint = _sourceLayer.anchorPoint;
    toLayer.filters = _sourceLayer.filters;
    toLayer.contentsGravity = _sourceLayer.contentsGravity;
    toLayer.contentsRect = _sourceLayer.contentsRect;
    toLayer.autoresizingMask = _sourceLayer.autoresizingMask;

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
        [CATransaction commit];
    }];

    [_sourceLayer.superlayer addSublayer:sourceLayer];
    [self setNeedsLayout];
    if (!self.allowResize)
    {
        sourceLayer.position = CGPointMake(sourceLayer.bounds.size.width/2, sourceLayer.bounds.size.height/2);
    }

    

   [sourceLayer addAnimation:transition forKey:kCATransition];
    [_sourceLayer addAnimation:transition forKey:kCATransition];
    
    

    [CATransaction commit];

    [self setupXAnimation:_scrollXSpeed];
    [self setupYAnimation:_scrollYSpeed];
    [CATransaction commit];
    
}


-(void)setSourceLayer:(CALayer *)sourceLayer
{
    

    [self copySourceSettings:sourceLayer];
    
    [_sourceLayer.superlayer replaceSublayer:_sourceLayer with:sourceLayer];
    
    _sourceLayer = sourceLayer;

    [self setNeedsLayout];
    /*
    if (!self.allowResize)
    {
        sourceLayer.position = CGPointMake(sourceLayer.bounds.size.width/2, sourceLayer.bounds.size.height/2);
    } else {
        sourceLayer.bounds = self.bounds;

        sourceLayer.position = CGPointMake(sourceLayer.bounds.size.width/2, sourceLayer.bounds.size.height/2);
    }*/

    [self setupXAnimation:_scrollXSpeed];
    [self setupYAnimation:_scrollYSpeed];
    [CATransaction commit];
    
}





-(void)setCropRect:(CGRect)cropRect
{
    self.sourceLayer.contentsRect = cropRect;
}


-(CGRect)cropRect
{
    return self.sourceLayer.contentsRect;
}


-(void)resizeSourceLayer:(CGRect)newFrame oldFrame:(CGRect)oldFrame
{
    
    
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


- (id<CAAction>)actionForKey:(NSString *)key
{
    if (self.disableAnimation)
    {
        return nil;
    }
    
    return [super actionForKey:key];
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
    
    CGPoint hitPointConv = [self convertPoint:hitPoint fromLayer:self.superlayer];
    if ([self containsPoint:hitPointConv])
    {
        CALayer *hitLayer =  [super hitTest:hitPoint];
        if (hitLayer == self || hitLayer == _sourceLayer || hitLayer == _xLayer || hitLayer == _yLayer)
        {
            return self;
        } else {
            return hitLayer;
        }
    } else {
        return nil;
    }
}

@end
