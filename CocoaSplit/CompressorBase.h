//
//  CompressorBase.h
//  CocoaSplit
//
//  Created by Zakk on 7/4/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "h264Compressor.h"


@class captureController;

@interface CompressorBase : NSObject <h264Compressor, NSCoding>
{
    NSMutableArray *_audioBuffer;
}



@property (strong) CaptureController *settingsController;


@property (strong) NSMutableDictionary *outputs;

@property (assign) int width;
@property (assign) int height;
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
