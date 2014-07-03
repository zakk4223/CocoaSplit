//
//  h264Compressor.h
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "CapturedFrameData.h"

//#import "OutputDestination.h"


@class CaptureController;
@class OutputDestination;
@protocol ControllerProtocol;


@protocol h264Compressor <NSObject,NSCoding>

//compressFrame is expected to be non-blocking. Create a serial dispatch queue if the underlying compressor
//is blocking

-(bool)compressFrame:(CapturedFrameData *)imageBuffer;


-(bool)setupCompressor;


@property (strong) id<ControllerProtocol> settingsController;
@property (strong) id<ControllerProtocol> outputDelegate;
@property (assign) bool isNew;
@property (strong) NSMutableString *name;
@property (strong) NSString *compressorType;


-(void) addOutput:(id)destination;
-(void) removeOutput:(id)destination;
-(bool) hasOutputs;






@end
