//
//  OutputDestination.h
//  H264Streamer
//
//  Created by Zakk on 9/16/12.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "VideoCompressor.h"
#import "CaptureController.h"
#import "CSLayoutRecorderInfoProtocol.h"
#import "CSStreamServiceProtocol.h"



@class FFMpegTask;

@interface OutputDestination : NSObject <NSCoding,NSCopying>

{
    NSString *_name;
    BOOL _active;
    double _output_start_time;
    NSMutableArray *_delayBuffer;
    BOOL _stopped;
    NSString *_destination;
    dispatch_queue_t _output_queue;
    int _p_buffered_frame_count;
    int _p_buffered_frame_size;
    int _p_dropped_frame_count;
    int _p_input_framecnt;
    int _p_output_framecnt;
    int _p_output_bytes;
    int _consecutive_dropped_frames;
    CFTimeInterval _compressor_delay_total;
    bool _output_prepared;
    
    
    
    CFAbsoluteTime _input_frame_timestamp;
    CFAbsoluteTime _output_frame_timestamp;
}



@property (strong) NSImage *statusImage;

@property (assign) BOOL captureRunning;

@property (assign) BOOL errored;
@property (strong) NSString *server_name;
@property (strong) NSString *type_name;
@property (strong) NSString *type_class_name;
@property (readonly) NSString *destination;
@property (strong) NSString *output_format;
@property (strong) NSString *stream_key;
@property (assign) int stream_delay;
@property (strong) NSObject<CSOutputWriterProtocol> *ffmpeg_out;
@property (weak) id<CSLayoutRecorderInfoProtocol> settingsController;
@property (strong) NSColor *textColor;
@property (assign) NSUInteger delay_buffer_frames;
@property (assign) BOOL buffer_draining;
@property (strong) NSString *name;
@property (strong) NSString *uuid;
@property (strong) NSObject<CSStreamServiceProtocol>*streamServiceObject;
@property (weak) SourceLayout *assignedLayout;
@property (strong) NSMutableDictionary *audioTracks;

//stats, mostly we just interrogate the ffmpeg_out object for these, but bouncing
//through this class allows us to be a bit smarter about the UI status updates

@property (assign) double input_framerate;
@property (assign) NSUInteger buffered_frame_count;
@property (assign) NSUInteger buffered_frame_size;
@property (assign) int dropped_frame_count;
@property (assign) double output_framerate;
@property (assign) double output_bitrate;
@property (assign) double average_compressor_delay;

@property (strong) NSObject <VideoCompressor> *compressor;
@property (strong) NSString *compressor_name;


@property (assign) BOOL active;

@property (assign) BOOL autoRetry;
@property (readonly) CAMultiAudioEngine *audioEngine;


-(id)initWithType:(NSString *)type;
-(void)stopOutput;
-(void) attachOutput;
-(void) writeEncodedData:(CapturedFrameData *)frameData;
-(void) updateStatistics;
-(void) reset;
-(void) setupCompressor;
-(void) setup;
-(void) teardown;
-(void)addAudioTrack:(CAMultiAudioOutputTrack *)track;
-(void)removeAudioTrack:(CAMultiAudioOutputTrack *)track;







@end

