//
//  OutputDestination.h
//  H264Streamer
//
//  Created by Zakk on 9/16/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "h264Compressor.h"
#import "CaptureController.h"



@class FFMpegTask;

@interface OutputDestination : NSObject <NSCoding,NSCopying>

{
    NSString *_destination;
    NSString *_name;
    BOOL _active;
    double _output_start_time;
    NSMutableArray *_delayBuffer;
    BOOL _stopped;
    
    
    
}


@property (strong) NSString *server_name;
@property (strong) NSString *type_name;
@property (strong) NSString *type_class_name;
@property (strong) NSString *destination;
@property (strong) NSString *output_format;
@property (strong) NSString *stream_key;
@property (assign) int stream_delay;
@property (strong) FFMpegTask *ffmpeg_out;
@property (strong) CaptureController *settingsController;
@property (strong) NSColor *textColor;
@property (assign) NSUInteger delay_buffer_frames;
@property (assign) BOOL buffer_draining;
@property (strong) NSString *name;
@property (strong) NSObject<CSStreamServiceProtocol>*streamServiceObject;

//stats, mostly we just interrogate the ffmpeg_out object for these, but bouncing
//through this class allows us to be a bit smarter about the UI status updates

@property (assign) double input_framerate;
@property (assign) int buffered_frame_count;
@property (assign) int buffered_frame_size;
@property (assign) int dropped_frame_count;
@property (assign) double output_framerate;
@property (assign) double output_bitrate;
@property (strong) NSObject <h264Compressor> *compressor;
@property (strong) NSString *compressor_name;


@property (assign) BOOL active;



-(id)initWithType:(NSString *)type;
-(void)stopOutput;
-(void) attachOutput;
-(void) writeEncodedData:(CapturedFrameData *)frameData;
-(void) updateStatistics;
-(void) reset;
-(void) setupCompressor;





@end

