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


//Shout out to user3125367 on stack overflow

- (CGPathRef)CGPathFromPath:(NSBezierPath *)path
{
    if ([path respondsToSelector:@selector(CGPath)])
    {
        return [path CGPath];
    }
    
    CGMutablePathRef cgPath = CGPathCreateMutable();
    NSInteger n = [path elementCount];
    
    for (NSInteger i = 0; i < n; i++) {
        NSPoint ps[3];
        switch ([path elementAtIndex:i associatedPoints:ps]) {
            case NSMoveToBezierPathElement: {
                CGPathMoveToPoint(cgPath, NULL, ps[0].x, ps[0].y);
                break;
            }
            case NSLineToBezierPathElement: {
                CGPathAddLineToPoint(cgPath, NULL, ps[0].x, ps[0].y);
                break;
            }
            case NSCurveToBezierPathElement: {
                CGPathAddCurveToPoint(cgPath, NULL, ps[0].x, ps[0].y, ps[1].x, ps[1].y, ps[2].x, ps[2].y);
                break;
            }
            case NSClosePathBezierPathElement: {
                CGPathCloseSubpath(cgPath);
                break;
            }
            default: NSAssert(0, @"Invalid NSBezierPathElement");
        }
    }
    return cgPath;
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
        [pathFunction callWithArguments:@[newPath, [JSValue valueWithRect:withFrame inContext:self.jsCtx]]];
        CGPathRef cgPath = [self CGPathFromPath:newPath];
        forLayer.path = cgPath;
        
    }
    
}



@end
