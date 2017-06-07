//
//  CSShapeWrapper.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 8/2/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "CSShapeLayer.h"

@interface CSShapeWrapper : NSObject


@property (strong) NSString *name;
@property (strong) NSString *path;
@property (strong) JSContext *jsCtx;



-(instancetype)initWithName:(NSString *)name usingPath:(NSString *)path;

-(void)getCGPath:(NSRect)withFrame forLayer:(CSShapeLayer *)forLayer;


@end
