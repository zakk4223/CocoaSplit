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
    // Drawing code here.
    //CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    NSGradient *grad = [[NSGradient alloc] initWithColorsAndLocations:[NSColor greenColor], 0.0f, [NSColor yellowColor], 0.5f, [NSColor redColor], 1.0f, nil];
    NSRect dRect = dirtyRect;
    
    float myRange = self.endValue - self.startValue;
    
    
    if (_isVertical)
    {
        dRect.size.height = (self.level/myRange) * self.bounds.size.height;
    } else {
        dRect.size.width = (self.level/myRange) * self.bounds.size.width;
    }
    

    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:dirtyRect];
    borderPath.lineWidth = self.backgroundSize;
    [borderPath stroke];
    if (self.level > 0)
    {
        NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect:dRect];
        [clipPath stroke];
        [clipPath setClip];
        [grad drawInRect:NSInsetRect(dirtyRect, self.backgroundSize, self.backgroundSize) angle:0.0f];
    }
    [super drawRect:dirtyRect];

}



-(float)level
{
    return _level;
}

-(void)setLevel:(float)level
{
    
    _level = level;
    
    [self display];

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
}


@end
