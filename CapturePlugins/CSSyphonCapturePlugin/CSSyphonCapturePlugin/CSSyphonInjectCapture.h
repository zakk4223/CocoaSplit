//
//  CSSyphonInjectCapture.h
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 12/7/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "SyphonCapture.h"
#import <ScriptingBridge/ScriptingBridge.h>


@interface CSSyphonInjectCapture : SyphonCapture


@property (strong) NSString *injectedAppName;
@property (strong) SBApplication *injectSB;
@property (strong) NSString *lastAppID;


-(void)changeBuffer;
-(void)toggleFast;
-(void)setBufferDimensions:(int)x_offset y_offset:(int)y_offset width:(int)width height:(int)height;


@end
