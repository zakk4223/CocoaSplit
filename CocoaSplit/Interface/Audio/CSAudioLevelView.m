//
//  CSAudioLevelView.m
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//

#import "CSAudioLevelView.h"
#import "CSNotifications.h"

@implementation CSAudioLevelView
@synthesize audioLevels = _audioLevels;



-(float)convertDbToLinear:(float)dbVal
{
    float minDB = -60.0f;
    float level;
    if (dbVal < minDB)
    {
        level = 0.0f;
    } else if (dbVal >= 0.0f) {
        level = 1.0f;
    } else {
        //Just try a percentage?
        
        float rawpercent = dbVal/60.0f;
        level = 1.0f - fabs(rawpercent);
    }

    return level;
}
- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
    //CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [super drawRect:dirtyRect];

    NSGradient *leftgrad;
    NSGradient *backgroundGrad;
    
    if (!self.audioLevels)
    {
        //return;
    }
    NSNumber *level1 = nil;
    NSNumber *level2 = nil;
    
    if (self.audioLevels.count > 0)
    {
        NSUInteger chanIdx = 0;
        if (self.useChannel > -1)
        {
            chanIdx = self.useChannel;
        }
            
        level1 = [self.audioLevels objectAtIndex:chanIdx];
        level2 = level1;
    }
    
    if (self.splitMeter && self.audioLevels.count > 1)
    {
        level2 = [self.audioLevels objectAtIndex:1];
    }
    
    if (!level1)
    {
        level1 = @(-60.0f);
        level2 = level1;
    }
    
    float useLevel = [self convertDbToLinear:level1.floatValue];
    float useLevel2 = [self convertDbToLinear:level2.floatValue];

    leftgrad = [[NSGradient alloc] initWithColorsAndLocations:[NSColor greenColor], 0.0f, [NSColor yellowColor], 0.667f, [NSColor redColor], 1.0f, nil];
    //backgroundGrad = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithRed:0.0f green:0.2f blue:0.0 alpha:1.0], 0.0f, [NSColor colorWithRed:0.2f green:0.2f blue:0.0f alpha:1.0f], 0.5f, [NSColor colorWithRed:0.2f green:0.0f blue:0.0f alpha:1.0f], 1.0f, nil];
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:dirtyRect];
    borderPath.lineWidth = self.backgroundSize;
    [borderPath stroke];
    [backgroundGrad drawInRect:NSInsetRect(dirtyRect, self.backgroundSize, self.backgroundSize) angle:0.0f];
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
    if (self.splitMeter)
    {
        NSBezierPath *linePath = [NSBezierPath bezierPath];
        if (_isVertical)
        {
            [linePath moveToPoint:NSMakePoint(self.bounds.size.width/2, 0)];
            [linePath lineToPoint:NSMakePoint(self.bounds.size.width/2, MAX(l1point,l2point))];
        } else {
            [linePath moveToPoint:NSMakePoint(0.0f, self.bounds.size.height/2)];
           // [linePath lineToPoint:NSMakePoint(MAX(l1point,l2point), self.bounds.size.height/2)];
            [linePath lineToPoint:NSMakePoint(NSMaxX(dirtyRect), self.bounds.size.height/2)];
        }
        [linePath stroke];
    }
}



-(void)notificationRan:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    self.useChannel = -1;
    
    if (!self.backgroundColor)
    {
        self.backgroundColor = [NSColor disabledControlTextColor];
    }
    if (self.frame.size.height > self.frame.size.width)
    {
        _isVertical = YES;
    }

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(notificationRan:) name:CSNotificationAudioStatisticsUpdate object:nil];
    
}

-(void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
