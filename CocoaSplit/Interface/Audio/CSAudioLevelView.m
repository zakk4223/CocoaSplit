//
//  CSAudioLevelView.m
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//

#import "CSAudioLevelView.h"

@implementation CSAudioLevelView
@synthesize level = _level;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}



-(float)level
{
    return _level;
}

-(void)setLevel:(float)level
{
    
    float myRange = self.endValue - self.startValue;
    CALayer *mLayer = _maskLayer;
    
    
    
    CGRect cFrame = self.frame;
    CGRect nFrame = CGRectMake(0,0,cFrame.size.width, cFrame.size.height);
    if (_isVertical)
    {
        nFrame.size.height = (level/myRange) * cFrame.size.height;
    } else {
        nFrame.size.width = (level/myRange) * cFrame.size.width;
    }

        [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [mLayer setFrame:nFrame];
    [CATransaction commit];
}

/*
-(instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        [self setupLayers];
    }
    
    return self;
}

 */



-(void)awakeFromNib
{
    [super awakeFromNib];
    if (!self.backgroundColor)
    {
        self.backgroundColor = [NSColor disabledControlTextColor];
    }
    [self setupLayers];
}

-(void)setupLayers
{
    if (_maskLayer)
    {
        return;
    }
    
    _isVertical = NO;
    
    if (self.frame.size.height > self.frame.size.width)
    {
        _isVertical = YES;
    }
    
    CALayer *outerLayer = [CALayer layer];
    outerLayer.borderWidth = self.backgroundSize;
    outerLayer.backgroundColor = self.backgroundColor.CGColor;
    
    CAGradientLayer *gLayer = [CAGradientLayer layer];
    NSArray *colors = [NSArray arrayWithObjects:(__bridge id)([NSColor greenColor].CGColor), (__bridge id)[NSColor yellowColor].CGColor, (__bridge id)[NSColor yellowColor].CGColor, (__bridge id)[NSColor redColor].CGColor, nil];
    gLayer.colors = colors;
    
    if (_isVertical)
    {
        gLayer.startPoint = CGPointMake(0.5, 0.0);
        gLayer.endPoint = CGPointMake(0.5, 1.0);
        
    } else {
        
        gLayer.startPoint = CGPointMake(0.0, 0.5);
        gLayer.endPoint = CGPointMake(1.0, 0.5);
    }
    
    self.layer = outerLayer;
    self.wantsLayer = YES;
    
    [outerLayer addSublayer:gLayer];
    
    gLayer.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    _maskLayer = [CALayer layer];
    
    
    _maskLayer.backgroundColor = [NSColor blackColor].CGColor;
    
    
    CGRect maskFrame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    if (_isVertical)
    {
        maskFrame.size.height = 0.0;
    } else {
        maskFrame.size.width = 0.0;
    }
    _maskLayer.frame = maskFrame;
    gLayer.mask = _maskLayer;

}

@end
