//
//  CSShapeWrapper.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 8/2/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSShapeLayer.h"

@interface CSShapeWrapper : NSObject

@property (nonatomic, strong) __attribute__((NSObject)) CGPathRef newPath;

-(void)getcgpath:(NSRect)withFrame forLayer:(CSShapeLayer *)forLayer;


@end
