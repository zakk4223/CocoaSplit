//
//  CSTimedOutputBuffer.m
//  CocoaSplit
//
//  Created by Zakk on 4/2/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSTimedOutputBuffer.h"
#import "AppDelegate.h"

@implementation CSTimedOutputBuffer



-(instancetype) init
{
    if (self = [super init])
    {
        _frameBuffer = [[NSMutableArray alloc] init];
        _name = @"Instant Recording";
    }
    return self;
}

-(instancetype) initWithCompressor:(id<VideoCompressor>)compressor
{
    if (self = [self init])
    {
        _compressor = compressor;
        [_compressor addOutput:self];
    }
    
    return self;
}

-(void) writeCurrentBuffer:(NSString *)toFile
{
    AppDelegate *appD = NSApp.delegate;
    CaptureController *controller = appD.captureController;
    
    
    FFMpegTask *newout = [[FFMpegTask alloc] init];
    
    newout.video_codec_id  = self.compressor.codec_id;
    newout.framerate = controller.captureFPS;
    newout.stream_output = [toFile stringByStandardizingPath];
    newout.settingsController = controller;
    newout.samplerate = controller.audioSamplerate;
    newout.audio_bitrate = controller.audioBitrate;

    NSMutableArray *fCopy;
    @synchronized(self) {
        fCopy = _frameBuffer.copy;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (CapturedFrameData *cData in fCopy)
        {
            [newout writeEncodedData:cData];
        }
        [newout stopProcess];
    });

}


-(void) writeEncodedData:(CapturedFrameData *)frameData
{
 
    
    float frameDuration = CMTimeGetSeconds(frameData.videoDuration);
    
    @synchronized(self) {
        [_frameBuffer addObject:frameData];
    }
    _currentBufferDuration  += frameDuration;
    
    //Drain the buffer if we need to
    //Try to always have a keyframe at the head of the buffer, even if it means we have to fudge the duration a bit
    
    while (_currentBufferDuration > self.bufferDuration)
    {
       
        float deleteDuration = 0.0f;
        
        //gobble until first keyFrame
        
        int delcnt = 0;
        NSMutableArray *fCopy;
        @synchronized(self) {
            fCopy = _frameBuffer.copy;
        }
        
        for (CapturedFrameData *cFrame in fCopy)
        {
            deleteDuration += CMTimeGetSeconds(cFrame.videoDuration);
            delcnt++;

            if (cFrame.isKeyFrame)
            {
                break;
            }
        }
        
        if ((_currentBufferDuration - deleteDuration) < self.bufferDuration)
        {
            //We'd have to delete too much, just leave it for now, we'll get it next time.
            break;
        }
        
        if (delcnt > 0)
        {
            @synchronized(self) {
                [_frameBuffer removeObjectsInRange:NSMakeRange(0, delcnt)];
            }
            _currentBufferDuration -= deleteDuration;
        }
    }
 
    
}

@end
