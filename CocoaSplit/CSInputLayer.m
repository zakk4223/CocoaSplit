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
@dynamic fakeHeight;
@dynamic fakeWidth;






-(instancetype)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer])
    {
        self.fakeHeight = ((CALayer *)layer).bounds.size.height;
        self.fakeWidth = ((CALayer *)layer).bounds.size.width;

    }
    
    return self;
}

+(BOOL)needsDisplayForKey:(NSString *)key
{
    if ([@"fakeWidth" isEqualToString:key] || [@"fakeHeight" isEqualToString:key])
    {
        return YES;
    }
    
    return [super needsDisplayForKey:key];
}

-(void)display
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self setValue:@([self.presentationLayer fakeWidth]) forKeyPath:@"bounds.size.width"];
    [self setValue:@([self.presentationLayer fakeHeight]) forKeyPath:@"bounds.size.height"];

    [CATransaction commit];
    
    
}



-(void)frameTick
{

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
        
        self.layoutManager = [CAConstraintLayoutManager layoutManager];
        
        
        _allowResize = YES;
        _sourceLayer = [CALayer layer];
        _sourceLayer.anchorPoint = CGPointMake(0.0, 0.0);
        _sourceLayer.contentsGravity = kCAGravityResizeAspect;
        _sourceLayer.frame = CGRectMake(0, 0, 1, 1);
        _scrollAnimation = [CABasicAnimation animation];
        _scrollAnimation.repeatCount = HUGE_VALF;
        self.zPosition = 0;
        _xLayer.layoutManager = self.layoutManager;
        _yLayer.layoutManager = self.layoutManager;
        
        [_xLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
        [_xLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
        [_xLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        [_xLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];


        [_yLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
        [_yLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
        [_yLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        [_yLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];

        [_sourceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
        [_sourceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
        [_sourceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX]];
        [_sourceLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];

        
        _xLayer.delegate = self;
        _yLayer.delegate = self;
        
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



-(void)copySourceSettings:(CALayer *)toLayer
{
    toLayer.anchorPoint = _sourceLayer.anchorPoint;
    toLayer.filters = _sourceLayer.filters;
    toLayer.contentsGravity = _sourceLayer.contentsGravity;
    toLayer.contentsRect = _sourceLayer.contentsRect;
    toLayer.autoresizingMask = _sourceLayer.autoresizingMask;
    toLayer.constraints = _sourceLayer.constraints;
    toLayer.delegate = self;
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


-(CALayer *)sourceLayer
{
    return _sourceLayer;
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



-(id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return (id<CAAction>)[NSNull null];
}


- (id<CAAction>)actionForKey:(NSString *)key
{
    
    return nil;
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
