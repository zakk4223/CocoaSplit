//
//  CSFFMpegPlayer.h
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "CSFFMpegInput.h"
#import "CSPcmPlayer.h"


typedef enum ff_movie_repeat_t {
    kCSFFMovieRepeatNone = 0,
    kCSFFMovieRepeatOne = 1,
    kCSFFMovieRepeatAll = 2
} ff_movie_repeat;


@interface CSFFMpegPlayer : NSObject
{
    CFTimeInterval _first_frame_host_time;
    AVFrame *_peek_frame;
    CVPixelBufferRef _last_buf;
    dispatch_queue_t _input_read_queue;
    dispatch_queue_t _audio_queue;
    bool _audio_done;
    bool _video_done;
    CVPixelBufferPoolRef *_cvpool;
    NSSize _currentSize;
    bool _nextFlag;
    int64_t _first_video_pts;
    bool _flushAudio;
    int _doneDirection;
    CSFFMpegInput *_forceNextInput;
    bool _seekRequest;
    double _seekRequestTime;
    bool _audio_running;
    int64_t _first_pts;
    
    
    
    
    
}



@property (strong) NSMutableArray *inputQueue;
@property (strong) CSPcmPlayer *pcmPlayer;
@property (assign) bool paused;
@property (assign) bool playing;

@property (strong) CSFFMpegInput *currentlyPlaying;
@property (assign) AudioStreamBasicDescription *asbd;

@property (copy, nonatomic) void (^itemStarted)(CSFFMpegInput *);
@property (copy, nonatomic) void (^pauseStateChanged)(void);
@property (copy, nonatomic) void (^queueStateChanged)(void);


@property (assign) double lastVideoTime;
@property (assign) double videoDuration;
@property (assign) bool muted;
@property (assign) bool seeking;
@property (assign) bool audio_needs_restart;
@property (assign) ff_movie_repeat repeat;





-(void)nextItem;
-(void)previousItem;
-(void)enqueueItem:(CSFFMpegInput *)item;
-(void)play;
-(void)stop;
-(void)next;
-(void)pause;
-(void)back;
-(void)playAndAddItem:(CSFFMpegInput *)item;




-(void)seek:(double)toTime;
-(void)startAudio;



-(CVPixelBufferRef)frameForMediaTime:(CFTimeInterval)mediaTime;
-(CVPixelBufferRef)firstFrame;



@end
