//
//  CSAudioLevelView.m
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//

#import "CSAudioLevelView.h"

@implementation CSAudioLevelView
@synthesize level = _level;
@synthesize level2 = _level2;


-(float)convertDbToLinear:(float)dbVal
{
    float minDB = -160.0f;
    float level;
    if (dbVal < minDB)
    {
        level = 0.0f;
    } else if (dbVal >= 0.0f) {
        level = 1.0f;
    } else {
        float minAmp = powf(10.0f, 0.05f * minDB);
        float invAmpRange = 1.0f/(1.0f - minAmp);
        float amp = powf(10.0f, 0.05f * dbVal);
        float adjAmp = (amp - minAmp) * invAmpRange;
        level = powf(adjAmp, 1.0f/2.0f);
    }

    return level;
}
- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    //CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [super drawRect:dirtyRect];

    NSGradient *leftgrad;
    NSGradient *rightgrad;
    
    NSRect lRect = dirtyRect;
    NSRect rRect = dirtyRect;

    float useLevel = [self convertDbToLinear:self.level];
    float useLevel2 = useLevel;
    if (self.channelCount > 1)
    {
        useLevel2 = [self convertDbToLinear:self.level2];
    }
    
    
    if (self.channelCount > 1)
    {
        leftgrad = [[NSGradient alloc] initWithColorsAndLocations:[NSColor greenColor], 0.0f, [NSColor yellowColor], 0.5f, [NSColor redColor], 1.0f, nil];
        rightgrad = [[NSGradient alloc] initWithColorsAndLocations:[NSColor redColor], 0.0f, [NSColor yellowColor], 0.5f, [NSColor greenColor], 1.0f, nil];
    } else {
        leftgrad = [[NSGradient alloc] initWithColorsAndLocations:[NSColor greenColor], 0.0f, [NSColor yellowColor], 0.5f, [NSColor redColor], 1.0f, nil];
    }
    
    

    /*

    if (_isVertical)
    {
        if (self.channelCount > 1)
        {
            lRect.size.height = useLevel * (self.bounds.size.height/2);
            rRect.size.height = useLevel2 * (self.bounds.size.width/2);
            rRect.origin.y = self.bounds.size.height - rRect.size.height;
        } else {
            lRect.size.height = (useLevel) * self.bounds.size.height;
        }
    } else {
        if (self.channelCount > 1)
        {
            lRect.size.width = useLevel * (self.bounds.size.width/2);
            rRect.size.width = useLevel2 * (self.bounds.size.width/2);
            rRect.origin.x = self.bounds.size.width - rRect.size.width;
        } else {
            lRect.size.width = (useLevel) * self.bounds.size.width;
        }
    }
    */

    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:dirtyRect];
    borderPath.lineWidth = self.backgroundSize;
    [borderPath stroke];
    
    NSBezierPath *clipPath = [NSBezierPath bezierPath];
    CGFloat l2point;
    CGFloat l1point;
    if (_isVertical)
    {
        l2point = useLevel2 * self.bounds.size.height;
        l1point = useLevel * self.bounds.size.height;
    } else {
        l2point = useLevel2 * self.bounds.size.width;
        l1point = useLevel * self.bounds.size.width;
    }
    [NSGraphicsContext saveGraphicsState];
    [clipPath moveToPoint:NSMakePoint(0.0, 0.0)];
    if (_isVertical)
    {
        [clipPath lineToPoint:NSMakePoint(self.bounds.size.width, 0)];
        [clipPath lineToPoint:NSMakePoint(self.bounds.size.width, l2point)];
        [clipPath lineToPoint:NSMakePoint(self.bounds.size.width/2, l2point)];
        [clipPath lineToPoint:NSMakePoint(self.bounds.size.width/2, l1point)];
        [clipPath lineToPoint:NSMakePoint(0, l1point)];
    } else {
        [clipPath lineToPoint:NSMakePoint(l2point, 0)];
        [clipPath lineToPoint:NSMakePoint(l2point, self.bounds.size.height/2)];
        [clipPath lineToPoint:NSMakePoint(l1point, self.bounds.size.height/2)];
        [clipPath lineToPoint:NSMakePoint(l1point, self.bounds.size.height)];
        [clipPath lineToPoint:NSMakePoint(0, self.bounds.size.height)];
    }
    [clipPath closePath];
    
    [clipPath stroke];
    [clipPath setClip];
    
    [leftgrad drawInRect:NSInsetRect(dirtyRect, self.backgroundSize, self.backgroundSize) angle:0.0f];
    [NSGraphicsContext restoreGraphicsState];
    if (self.channelCount > 1)
    {
        NSBezierPath *linePath = [NSBezierPath bezierPath];
        if (_isVertical)
        {
            [linePath moveToPoint:NSMakePoint(self.bounds.size.width/2, 0)];
            [linePath lineToPoint:NSMakePoint(self.bounds.size.width/2, MAX(l1point,l2point))];
        } else {
            [linePath moveToPoint:NSMakePoint(0.0f, self.bounds.size.height/2)];
            [linePath lineToPoint:NSMakePoint(MAX(l1point,l2point), self.bounds.size.height/2)];
        }
        [linePath stroke];
    }
}



-(float)level
{
    return _level;
}

-(void)setLevel:(float)level
{
    
    _level = level;
    
    [self setNeedsDisplay:YES];

}


-(float)level2
{
    return _level2;
}

-(void)setLevel2:(float)level
{
    
    _level2 = level;
    
    [self setNeedsDisplay:YES];
    
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    if (!self.backgroundColor)
    {
        self.backgroundColor = [NSColor disabledControlTextColor];
    }
    if (self.frame.size.height > self.frame.size.width)
    {
        _isVertical = YES;
    }
    _level = _level2 = -240.0f;
}


@end
