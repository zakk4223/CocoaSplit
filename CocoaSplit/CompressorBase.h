//
//  CompressorBase.h
//  CocoaSplit
//
//  Created by Zakk on 7/4/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OutputDestination.h"
#import "h264Compressor.h"

@interface CompressorBase : NSObject <h264Compressor, NSCoding>
{
    NSMutableArray *_audioBuffer;
}



@property (strong) id<ControllerProtocol> settingsController;
@property (strong) id<ControllerProtocol> outputDelegate;


@property (strong) NSMutableDictionary *outputs;

@property (assign) int width;
@property (assign) int height;
@property (assign) int working_width;
@property (assign) int working_height;

@property (strong) NSString *resolutionOption;

@property (strong) NSArray *arOptions;

@property (assign) bool isNew;
@property (strong) NSString *compressorType;
@property (strong) NSMutableString *name;
@property (assign) bool errored;




-(void) reset;
-(BOOL) setupResolution:(CVImageBufferRef)withFrame;
-(void) addAudioData:(CMSampleBufferRef)audioData;
-(void) setAudioData:(CapturedFrameData *)forFrame syncObj:(id)syncObj;




@end
