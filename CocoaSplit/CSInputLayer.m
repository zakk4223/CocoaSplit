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
@synthesize startColor = _startColor;
@synthesize stopColor = _stopColor;

@dynamic fakeHeight;
@dynamic fakeWidth;




-(void)invalidateLayoutOfLayer:(CALayer *)layer
{
    return [self.layoutManager invalidateLayoutOfLayer:layer];
}

-(void)layoutSublayersOfLayer:(CALayer *)layer
{

    [self.layoutManager layoutSublayersOfLayer:layer];

    if (layer == _xLayer)
    {
        for (CALayer *sLayer in _xLayer.sublayers)
        {
            CGSize newSize = [self preferredSizeOfLayer:sLayer];
            CGRect bounds = sLayer.bounds;
            bounds.size = newSize;
            sLayer.bounds = bounds;
            
        }
        [self setupXAnimation:self.scrollXSpeed];
        [self setupYAnimation:self.scrollYSpeed];
    }
    

}

-(CGSize)preferredSizeOfLayer:(CALayer *)layer
{
    
    CGSize retSize = [self.layoutManager preferredSizeOfLayer:layer];
    if ([layer isKindOfClass:[CATextLayer class]])
    {
        NSAttributedString *lText = ((CATextLayer *)layer).string;
        if (self.scrollXSpeed != 0)
        {
            
            if (lText.size.width > self.bounds.size.width)
            {
                retSize.width = lText.size.width;
            } else {
                retSize.width = self.bounds.size.width;
            }
        }
        
        if (self.scrollYSpeed != 0)
        {
            if (lText.size.height > self.bounds.size.height)
            {
                retSize.height = lText.size.height;
            } else {
                retSize.height = self.bounds.size.height;
            }

        }
    }
    return retSize;
}

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
    
    [self setValue:@([self.presentationLayer fakeWidth]) forKeyPath:@"bounds.size.width"];
    [self setValue:@([self.presentationLayer fakeHeight]) forKeyPath:@"bounds.size.height"];
    
}


-(void)clearGradient
{
    _startColor = _stopColor = nil;
    [self setupColors];
    
    self.startColor = nil;
    self.stopColor = nil;
}


-(void)setGradientStartX:(CGFloat)gradientStartX
{
    
    CGPoint cBounds = self.startPoint;
    cBounds.x = gradientStartX;
    self.startPoint = cBounds;
}

-(CGFloat)gradientStartX
{
    return self.startPoint.x;
}


-(void)setGradientStartY:(CGFloat)gradientStartY
{
    
    CGPoint cBounds = self.startPoint;
    cBounds.y = gradientStartY;
    self.startPoint = cBounds;
}



-(CGFloat)gradientStartY
{
    return self.startPoint.y;
}

-(void)setGradientStopX:(CGFloat)gradientStopX
{
    CGPoint cBounds = self.endPoint;
    cBounds.x = gradientStopX;
    self.endPoint = cBounds;
}

-(CGFloat)gradientStopX
{
    return self.endPoint.x;
}

-(void)setGradientStopY:(CGFloat)gradientStopY
{
    CGPoint cBounds = self.endPoint;
    cBounds.y = gradientStopY;
    self.endPoint = cBounds;
}

-(CGFloat)gradientStopY
{
    return self.endPoint.y;
}


-(void)setupColors
{
    
    if (!self.startColor && !self.stopColor)
    {
        self.colors = nil;
        return;
    }
    
    CGColorRef firstColor;
    CGColorRef lastColor;
    if (!self.startColor)
    {
        firstColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    } else {
        firstColor = [self.startColor CGColor];
    }
    
    if (!self.stopColor)
    {
        lastColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    } else {
        lastColor = [self.stopColor CGColor];
    }

    
    CGColorRetain(firstColor);
    CGColorRetain(lastColor);
    
    self.colors = [NSArray arrayWithObjects:CFBridgingRelease(firstColor),CFBridgingRelease(lastColor), nil];
    
}

-(void)setStartColor:(NSColor *)startColor
{
    

    _startColor = startColor;
    
    
    [self setupColors];
    
}



-(NSColor *)startColor
{
    return _startColor;
}


-(void)setStopColor:(NSColor *)stopColor
{
    
    _stopColor = stopColor;
    
    [self setupColors];
}



-(NSColor *)stopColor
{
    return _stopColor;
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
        _xLayer.layoutManager = self;
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
        
        _xLayer.masksToBounds = NO;
        _yLayer.masksToBounds = NO;
        
        self.masksToBounds = YES;
        _yLayer.anchorPoint = CGPointMake(0.0, 0.0);
        
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
    }
    
    return self;
}


-(void)setScrollXSpeed:(float)scrollXSpeed
{
    _scrollXSpeed = scrollXSpeed;
    [_xLayer setNeedsLayout];
    
    if (scrollXSpeed == 0)
    {
        _xLayer.instanceCount = 1;
        [_yLayer removeAnimationForKey:@"position.x"];
        
    } else {
        _xLayer.instanceCount = 2;
        [self setupXAnimation:scrollXSpeed];
    }

    
    
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


-(void)transitionsDisabled
{
    _yLayer.hidden = NO;
}


-(void)transitionToLayer:(CALayer *)toLayer fromLayer:(CALayer *)fromLayer withTransition:(CATransition *)transition
{
    CALayer *realTo = toLayer;
    CALayer *realFrom = fromLayer;
    
    if (toLayer == self)
    {
        realTo = _yLayer;
    }
    
    if (fromLayer == self)
    {
        realFrom = _yLayer;
    }
    
    
    [realTo addAnimation:transition forKey:nil];
    [realFrom addAnimation:transition forKey:nil];
    realFrom.hidden = YES;
    realTo.hidden = NO;
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
