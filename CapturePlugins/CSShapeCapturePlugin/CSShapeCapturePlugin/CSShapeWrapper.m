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
        CGPathRef cgPath = [newPath CGPath];
        forLayer.path = cgPath;
        
    }
    
}



@end
