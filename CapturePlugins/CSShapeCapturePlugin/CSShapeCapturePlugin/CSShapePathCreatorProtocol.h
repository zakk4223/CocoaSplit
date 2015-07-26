//
//  CSShapePathCreatorProtocol.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/25/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#ifndef CSShapeCapturePlugin_CSShapePathCreatorProtocol_h
#define CSShapeCapturePlugin_CSShapePathCreatorProtocol_h
#import <QuartzCore/QuartzCore.h>

@protocol CSShapePathCreatorProtocol


-(CGPathRef)create_cgpath:(NSRect)withFrame;

@end

#endif
