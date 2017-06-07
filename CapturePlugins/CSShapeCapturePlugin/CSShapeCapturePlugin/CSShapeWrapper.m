//
//  CSShapeWrapper.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 8/2/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "CSShapeWrapper.h"
#import "CSShapeCaptureFactory.h"


@interface NSBezierPath (CSCGPath)
    -(CGPathRef)CGPath;
    
@end

@implementation CSShapeWrapper

-(instancetype)initWithName:(NSString *)name usingPath:(NSString *)path
{
    if (self = [self init])
    {
        _name = name;
        _path = path;
    }
    
    return self;
}


- (CGPathRef)quartzPath:(NSBezierPath *)forPath
{
    int i, numElements;
    
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [forPath elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        
        for (i = 0; i < numElements; i++)
        {
            NSLog(@"PATH ELEMENT %d", i);
            switch ([forPath elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}


-(void)getCGPath:(NSRect)withFrame forLayer:(CSShapeLayer *)forLayer
{
    
    NSBezierPath *newPath = [[NSBezierPath alloc] init];
    
    if (!self.jsCtx)
    {
        self.jsCtx = [[JSContext alloc] init];
        
        [[CSShapeCaptureFactory sharedPathLoader] evaluateJavascriptAtPath:self.path usingContext:self.jsCtx];
    }
    
    JSValue *pathFunction = self.jsCtx[@"createPath"];

    if (pathFunction)
    {
        JSValue *jRect = [JSValue valueWithRect:withFrame inContext:self.jsCtx];
        
        JSValue *retVal = [pathFunction callWithArguments:@[newPath, jRect]];

        
        CGPathRef cgPath = [newPath CGPath];
        //[self quartzPath:newPath];
        forLayer.path = cgPath;
        
    }
    
}



@end
