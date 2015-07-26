//
//  CSShapeCapture.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/24/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSShapeCapture.h"
#import "CSShapeCaptureFactory.h"

@implementation CSShapeCapture

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize lineWidth = _lineWidth;
@synthesize fillColor = _fillColor;
@synthesize lineColor = _lineColor;
@synthesize backgroundColor = _backgroundColor;



-(void)encodeWithCoder:(NSCoder *)aCoder
{
    
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:self.lineColor forKey:@"lineColor"];
    [aCoder encodeObject:self.fillColor forKey:@"fillColor"];
    [aCoder encodeFloat:self.lineWidth forKey:@"lineWidth"];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    
    if (self = [super initWithCoder:aDecoder])
    {
        self.lineColor = [aDecoder decodeObjectForKey:@"lineColor"];
        self.fillColor = [aDecoder decodeObjectForKey:@"fillColor"];
        self.lineWidth = [aDecoder decodeFloatForKey:@"lineWidth"];
    }
    return self;
}


-(instancetype)init
{
    if (self = [super init])
    {
        _lineColor = [NSColor blackColor];
        _fillColor = [NSColor redColor];
        _lineWidth = 2.0f;

    }
    
    return self;
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
    
    CSShapePathLoader *sharedLoader = [CSShapeCaptureFactory sharedPathLoader];
    
    newLayer.shapeLoader = sharedLoader;
    
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
        newLayer.pathModule = self.activeVideoDevice.uniqueID;
    }
    newLayer.lineWidth = self.lineWidth;
    
    return newLayer;
}


-(CSAbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(CSAbstractCaptureDevice *)newDev
{
    
    
    _activeVideoDevice = newDev;
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSShapeLayer *)layer).pathModule = newDev.uniqueID;
        [(CSShapeLayer *)layer drawPath];
    }];
}



-(NSArray *) availableVideoDevices
{
    
    NSMutableArray *ret = [NSMutableArray array];
    CSShapePathLoader *sharedLoader = [CSShapeCaptureFactory sharedPathLoader];
    
    NSDictionary *allShapes = [sharedLoader allPaths];
    
    for(NSString *key in allShapes)
    {
        NSDictionary *shapeInfo = allShapes[key];
        CSAbstractCaptureDevice *shape = [[CSAbstractCaptureDevice alloc] initWithName:shapeInfo[@"name"] device:nil uniqueID:shapeInfo[@"module"]];
        [ret addObject:shape];
    }
    return ret;
}



+ (NSString *)label
{
    return @"Shape";
}



@end
