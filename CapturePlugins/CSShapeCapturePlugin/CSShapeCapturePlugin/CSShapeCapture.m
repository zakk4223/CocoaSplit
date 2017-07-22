//
//  CSShapeCapture.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/24/15.
//

#import "CSShapeCapture.h"
#import "CSShapeCaptureFactory.h"
#import <objc/runtime.h>

@implementation CSShapeCapture

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize lineWidth = _lineWidth;
@synthesize fillColor = _fillColor;
@synthesize lineColor = _lineColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize flipX = _flipX;
@synthesize flipY = _flipY;
@synthesize rotateAngle = _rotateAngle;


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:self.lineColor forKey:@"lineColor"];
    [aCoder encodeObject:self.fillColor forKey:@"fillColor"];
    [aCoder encodeFloat:self.lineWidth forKey:@"lineWidth"];
    [aCoder encodeFloat:self.rotateAngle forKey:@"rotateAngle"];
    [aCoder encodeBool:self.flipX forKey:@"flipX"];
    [aCoder encodeBool:self.flipY forKey:@"flipY"];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    //force python loading
    [CSShapeCaptureFactory sharedPathLoader];

    if (self = [super initWithCoder:aDecoder])
    {
        self.lineColor = [aDecoder decodeObjectForKey:@"lineColor"];
        self.fillColor = [aDecoder decodeObjectForKey:@"fillColor"];
        self.lineWidth = [aDecoder decodeFloatForKey:@"lineWidth"];
        self.rotateAngle = [aDecoder decodeFloatForKey:@"rotateAngle"];
        self.flipX = [aDecoder decodeBoolForKey:@"flipX"];
        self.flipY = [aDecoder decodeBoolForKey:@"flipY"];
    }
    return self;
}


-(instancetype)init
{
    if (self = [super init])
    {
        
        _lineColor = [NSColor blackColor];
        _fillColor = [NSColor whiteColor];
        _lineWidth = 2.0f;

    }
    
    return self;
}


-(void)setRotateAngle:(CGFloat)rotateAngle
{
    _rotateAngle = rotateAngle;
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).rotateAngle = rotateAngle;
        [(CSShapeLayer *)layer drawPath];
        
    }];
}

-(CGFloat)rotateAngle
{
    return _rotateAngle;
}


-(void)setFlipX:(bool)flipX
{
    _flipX = flipX;
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).flipX = flipX;
        [(CSShapeLayer *)layer drawPath];

    }];
}

-(bool)flipX
{
    return _flipX;
}

-(void)setFlipY:(bool)flipY
{
    _flipY = flipY;
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).flipY = flipY;
        [(CSShapeLayer *)layer drawPath];

    }];
}

-(bool)flipY
{
    return _flipY;
}


-(void)setFillColor:(NSColor *)fillColor
{
    
    CGColorRef setColor = NULL;
    
    if (fillColor)
    {
        setColor = [fillColor CGColor];
    }
    
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).fillColor = setColor;
    }];
    
    _fillColor = fillColor;
}

-(NSColor *)fillColor
{
    return _fillColor;
}


-(void)setLineColor:(NSColor *)lineColor
{
    
    CGColorRef setColor = NULL;
    
    if (lineColor)
    {
        setColor = [lineColor CGColor];
    }
    
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).strokeColor = setColor;
    }];
    
    _lineColor = lineColor;
}

-(NSColor *)lineColor
{
    return _lineColor;
}

-(void)setBackgroundColor:(NSColor *)backgroundColor
{
    
    CGColorRef setColor = NULL;
    
    if (backgroundColor)
    {
        setColor = [backgroundColor CGColor];
    }
    
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).backgroundColor = setColor;
    }];
    
    _backgroundColor = backgroundColor;
}

-(NSColor *)backgroundColor
{
    return _backgroundColor;
}


-(void)setLineWidth:(CGFloat)lineWidth
{
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).lineWidth = lineWidth;
    }];

}

-(CGFloat)lineWidth
{
    return _lineWidth;
}



-(CALayer *)createNewLayer
{


    CSShapeLayer *newLayer = [CSShapeLayer layer];
    
    
    
    if (self.fillColor)
    {
        newLayer.fillColor = [self.fillColor CGColor];
    }
    
    if (self.lineColor)
    {
        newLayer.strokeColor = [self.lineColor CGColor];
    }
    
    if (self.backgroundColor)
    {
        newLayer.backgroundColor = [self.backgroundColor CGColor];
    }
    
    if (self.activeVideoDevice)
    {
        newLayer.shapeCreator = self.activeVideoDevice.captureDevice;
        
    }
    newLayer.lineWidth = self.lineWidth;
    newLayer.flipX = self.flipX;
    newLayer.flipY = self.flipY;
    newLayer.rotateAngle = self.rotateAngle;
    
    
    return newLayer;
}


-(CSAbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(CSAbstractCaptureDevice *)newDev
{
    
    
    _activeVideoDevice = newDev;
    self.captureName = newDev.captureName;
    
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).shapeCreator = newDev.captureDevice;

        
        [(CSShapeLayer *)layer drawPath];
    }];
}



-(NSArray *) availableVideoDevices
{
    
    NSMutableArray *ret = [NSMutableArray array];
    CSShapePathLoader *sharedLoader = [CSShapeCaptureFactory sharedPathLoader];
    
    NSDictionary *allShapes = [NSDictionary dictionary];
    @try {
        allShapes = [sharedLoader allPaths];
    }
    @catch (NSException *exception) {
        NSLog(@"Loading available shapes failed with exception %@", exception);
    }
    
    for(NSString *key in allShapes)
    {
        NSDictionary *shapeInfo = allShapes[key];
        CSAbstractCaptureDevice *shape = [[CSAbstractCaptureDevice alloc] initWithName:shapeInfo[@"name"] device:shapeInfo[@"wrapper"] uniqueID:shapeInfo[@"path"]];
        [ret addObject:shape];
    }
    return ret;
}



+ (NSString *)label
{
    return @"Shape";
}



@end
