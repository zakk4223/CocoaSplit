//
//  CSFFMpegCapture.h
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/11/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCaptureBase.h"
#import "CSCaptureSourceProtocol.h"
#import "CSFFMpegInput.h"
#import "CSIOSurfaceLayer.h"
#import "CAMultiAudioPCM.h"
#import "CSPcmPlayer.h"
#import "CSPluginServices.h"
#import "CSFFMpegPlayer.h"





#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"
#import "libavutil/threadmessage.h"
#import "libavutil/pixfmt.h"
#import "libavutil/pixdesc.h"


@interface CSFFMpegCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    AVFormatContext *_avFmtCtx;
    AVThreadMessageQueue *_video_msg_queue;
    AVThreadMessageQueue *_audio_msg_queue;
    
    
    dispatch_queue_t _video_decoder_queue;
    dispatch_queue_t _media_reader_queue;
    CAMultiAudioPCM *_bufferPCM;
    AudioStreamBasicDescription _asbd;
    CFTimeInterval _lastTimeUpdate;
    
    
    
}


@property (strong) CSPcmPlayer *pcmPlayer;
@property (strong) CSFFMpegPlayer *player;

@property (strong) NSString *currentTimeString;
@property (strong) NSString *durationString;
@property (assign) double currentMovieTime;
@property (assign) double currentMovieDuration;


-(void)queuePath:(NSString *)path;

-(void)pause;
-(void)play;
-(void)mute;
-(void)next;
-(void)back;

@end
