//
//  CSShapeLayer.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/25/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CSShapePathCreatorProtocol.h"
#import "CSShapePathLoader.h"

@interface CSShapeLayer : CAShapeLayer

@property (strong) NSString *pathModule;
@property (strong) CSShapePathLoader *shapeLoader;

-(void)drawPath;

@end
