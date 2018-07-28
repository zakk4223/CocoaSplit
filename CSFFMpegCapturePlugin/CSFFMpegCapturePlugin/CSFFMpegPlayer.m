//
//  CSFFMpegPlayer.m
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSFFMpegPlayer.h"

@implementation CSFFMpegPlayer

@synthesize muted = _muted;


-(instancetype) init
{
    if (self = [super init])
    {
        _input_read_queue = dispatch_queue_create("FFMPEG PLAYER INPUT", DISPATCH_QUEUE_SERIAL);
        _audio_queue = dispatch_queue_create("FFMPEG PLAYER AUDIO", DISPATCH_QUEUE_SERIAL);
        _currentSize = NSZeroSize;
        _inputQueue = [[NSMutableArray alloc] init];
        _nextFlag = NO;
        _muted = NO;
        _doneDirection = 1;
        
    }
    
    return self;
}


-(void)removeObjectFromInputQueueAtIndex:(NSUInteger)index
{
    [_inputQueue removeObjectAtIndex:index];
    if (self.queueStateChanged)
    {
        self.queueStateChanged();
    }
}

-(void)insertObject:(NSObject *)object inInputQueueAtIndex:(NSUInteger)index
{
    [_inputQueue insertObject:object atIndex:index];
    if (self.queueStateChanged)
    {
        self.queueStateChanged();
    }

}



-(void)setMuted:(bool)muted
{
    _muted = muted;
    if (self.pcmPlayer)
    {
        
        self.pcmPlayer.muted = muted;
    }
}

-(bool)muted
{
    return _muted;
}




-(CSFFMpegInput *)preChangeItem
{
    CSFFMpegInput *useItem;
    _nextFlag = NO;
    @synchronized (self) {
        useItem = self.currentlyPlaying;
        self.currentlyPlaying = nil;
        _audio_done = NO;
        _audio_running = NO;
        _video_done = NO;
        _flushAudio = NO;
        _first_frame_host_time = 0;
    }
    
    if (useItem)
    {
        if (self.pcmPlayer)
        {
            [self.pcmPlayer flush];
        }
    }
    
    if (useItem)
    {
        [useItem closeMedia];
    }

    
    return useItem;

}


-(void)previousItem
{
    CSFFMpegInput *useItem = [self preChangeItem];
    
    if (!self.playing)
    {
        return;
    }
    
    NSInteger currentIdx = 0;
    
    currentIdx = [_inputQueue indexOfObject:useItem];
    
    currentIdx--;
    
    if (currentIdx < 0)
    {
        currentIdx = _inputQueue.count-1;
    }
    
    
    
    CSFFMpegInput *nextItem = nil;
    
    
    if (currentIdx >=0 && (currentIdx < _inputQueue.count))
    {
        nextItem = [_inputQueue objectAtIndex:currentIdx];

    }
    if (nextItem)
    {
        [self playItem:nextItem];
        //[self removeObjectFromInputQueueAtIndex:0];
        
    }
    
}


-(void)nextItem
{
    if (self.currentlyPlaying && (_inputQueue.count == 1) && (self.repeat == kCSFFMovieRepeatNone))
    {
        return;
    }
    CSFFMpegInput *useItem = [self preChangeItem];
    
    if (!self.playing)
    {
        return;
    }

    NSUInteger currentIdx = 0;
    
    if (useItem)
    {
        currentIdx = [_inputQueue indexOfObject:useItem];
        if (self.repeat == kCSFFMovieRepeatNone || self.repeat == kCSFFMovieRepeatAll)
        {
            currentIdx++;
        }

    }
    
    

    if (currentIdx >= _inputQueue.count)
    {
        if (self.repeat == kCSFFMovieRepeatNone)
        {
            [self stop];
            return;
        }
        currentIdx = 0;
    }
    
    CSFFMpegInput *nextItem = nil;
    
    
    
    if (currentIdx != NSNotFound && (currentIdx < _inputQueue.count))
    {
        nextItem = [_inputQueue objectAtIndex:currentIdx];
        
    }
    if (nextItem)
    {
        [self playItem:nextItem];
        //[self removeObjectFromInputQueueAtIndex:0];
        
    }
    
}


-(void)playAndAddItem:(CSFFMpegInput *)item;
{
    if ([_inputQueue indexOfObject:item] == NSNotFound)
    {
        [self enqueueItem:item];
    }
    
    if (!self.playing)
    {
        self.currentlyPlaying = item;
        [self playItem:item];
    } else {
        _forceNextInput = item;
        [self.currentlyPlaying stop];
    }
}


-(void)seek:(double)toTime
{
    _first_frame_host_time = 0;
    _peek_frame = NULL;
    _first_video_pts = 0;

    
    [self.currentlyPlaying seek:toTime];
    if (_audio_done)
    {
        [self startAudio];
    }
    _first_frame_host_time = 0;
    _peek_frame = NULL;
    _first_video_pts = 0;
    
    _seekRequest = NO;
    _seekRequestTime = 0.0f;
    _video_done = NO;
    _audio_done = NO;

    return;
    /*
    
    if (_seekRequest)
    {
        [self.currentlyPlaying seek:toTime];
        _first_frame_host_time = 0;
        _peek_frame = NULL;
        _first_video_pts = 0;
    
        _seekRequest = NO;
        _seekRequestTime = 0.0f;
        _video_done = NO;
        _audio_done = NO;

    } else {
        _seekRequest = YES;
        _seekRequestTime = toTime;

    }*/
    
}


-(void)playItem:(CSFFMpegInput *)item
{
    
    dispatch_async(_input_read_queue, ^{
        
        [item openMedia:20];
        
        if (self.itemStarted)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ self.itemStarted(item);});
        }

        self.lastVideoTime = 0.0f;
        self.videoDuration = item.duration;
        
        
        @synchronized (self) {
            self.currentlyPlaying = item;
            self.playing = YES;
        }
        [item start];
        
    });
}


-(void)enqueueItem:(CSFFMpegInput *)item
{
   [self insertObject:item inInputQueueAtIndex:self.inputQueue.count];
   if (self.inputQueue.count == 1)
    {
        [item openMedia:20];
    }
    
}


-(void)play
{
    self.playing = YES;
    if (!self.currentlyPlaying)
    {

            [self nextItem];
    } else {
        [self playItem:self.currentlyPlaying];
    }
    
    if (self.paused)
    {
        [self pause];
    } else {
    
        if (self.pauseStateChanged)
        {
            self.pauseStateChanged();
        }
    }
}

-(void)next
{
    _flushAudio = YES;
    _doneDirection = 1;
    [self.currentlyPlaying stop];
}

-(void)back
{
    _flushAudio = YES;
    if (self.lastVideoTime >= 1.5)
    {
        [self seek:0.0];
    } else {
        _doneDirection = -1;
        [self.currentlyPlaying stop];
    }
}


-(void)stop
{
    self.playing = NO;
    [self.currentlyPlaying closeMedia];
}

-(void)startAudio
{
    _audio_running = YES;
    
    dispatch_async(_audio_queue, ^{

        [self.pcmPlayer play];
        [self audioThread];
    });
}



-(void)audioThread
{
    
    
    int av_error = 0;
    CAMultiAudioPCM *audioPCM = NULL;
    bool good_audio = NO;
    _audio_done = NO;
    
    while (self.playing)
    {
        @autoreleasepool {
            if (self.paused)
            {
                //[self.pcmPlayer pause];
                return;
            }
            
            audioPCM = [self.currentlyPlaying consumeAudioFrame:self.asbd error_out:&av_error];
            if (!self.playing) break;
            if (av_error == AVERROR_EOF)
            {
                if (_flushAudio)
                {
                    [self.pcmPlayer flush];
                }
                break;
            }
            
            if (audioPCM)
            {
                if (audioPCM.bufferCount == -1 && audioPCM.frameCount == -1)
                {
                    if (good_audio)
                    {
                        //input needs us to flush the player, probably due to seek
                        [self.pcmPlayer flush];
                        [self.pcmPlayer play];
                        continue;
                    } else {
                        continue;
                    }
                }
                
                good_audio = YES;
                
                
            }
            
            
            if (!self.playing) break;
            
            if (self.pcmPlayer.pendingFrames > 60 || av_error == AVERROR(EAGAIN))
            {
                usleep(10000);
            }
            
            if (!self.playing) break;
            if (audioPCM)
            {
                [self.pcmPlayer playPcmBuffer:audioPCM];
            }
            if (self.paused)
            {
                [self.pcmPlayer pause];
                return;
            }
            
            if (!self.playing) break;
        }
    }
    _audio_done = YES;
    [self inputDone];
}


-(void)pause
{
    if (self.paused)
    {
        _first_video_pts = self.lastVideoTime / av_q2d(self.currentlyPlaying.videoTimeBase);
        _first_frame_host_time = CACurrentMediaTime();
        self.paused = NO;
        [self startAudio];
    } else {
        self.paused = YES;
    }
    
    if (self.pauseStateChanged)
    {
        self.pauseStateChanged();
    }
}


-(CVPixelBufferRef)firstFrame
{
    CSFFMpegInput *useInput;
    AVFrame *frame = NULL;
    
    @synchronized (self) {
        useInput = self.currentlyPlaying;
    }

    if (!useInput)
    {
        useInput = self.inputQueue.firstObject;
    }
    
    if (useInput)
    {
    
        frame = [useInput firstVideoFrame];
        if (frame)
        {
            CVPixelBufferRef ret = [self convertFrameToPixelBuffer:frame];
            return ret;
        }
    }
    return NULL;
}


-(CVPixelBufferRef)frameForMediaTime:(CFTimeInterval)mediaTime
{
    CSFFMpegInput *_useInput;
    
    @synchronized (self) {
         _useInput = self.currentlyPlaying;
    }
    
    if (!_useInput)
    {
        return nil;
    }
    
    if (_seekRequest)
    {
        [self seek:_seekRequestTime];
    }
    
    
    AVFrame *use_frame = NULL;
    CVPixelBufferRef ret = nil;
    int64_t audio_pts = 0;
    bool play_audio = YES;
    
    
    
    int av_error = 0;

    if (_first_frame_host_time == 0)
    {
        play_audio = NO;
        
        use_frame = [_useInput consumeFrame:&av_error];
        if (use_frame)
        {
            
            _first_frame_host_time = mediaTime;
            _peek_frame = NULL;
            _last_buf = nil;
            audio_pts = use_frame->pts;
            _first_video_pts = 0;
            //[self startAudio];
        }
    } else {
        if (!self.paused)
        {
            CFTimeInterval host_delta = mediaTime - _first_frame_host_time;
            
            int64_t target_pts = host_delta / av_q2d(self.currentlyPlaying.videoTimeBase);
            
            if (_first_video_pts)
            {
                target_pts += _first_video_pts;
            } else {
                target_pts += _useInput.first_video_pts;
            }
            
            audio_pts = target_pts;
            
            
            
            int consumed = 0;
            use_frame = NULL;
            bool do_consume = YES;
            
            if (_last_buf && _peek_frame)
            {
                
                if (_peek_frame->pts > target_pts)
                {
                    do_consume = NO;
                    
                } else {
                    use_frame = _peek_frame;
                    do_consume = YES;
                }
            }
            
            while (do_consume && (_peek_frame = [_useInput consumeFrame:&av_error]) && _peek_frame->pts < target_pts)
            {
                if (use_frame)
                {
                    av_frame_unref(use_frame);
                    av_frame_free(&use_frame);
                    
                }
                
                use_frame = _peek_frame;
                consumed++;
            }
            if (av_error == AVERROR_EOF)
            {
                av_frame_unref(use_frame);
                av_frame_free(&use_frame);
                _video_done = YES;
            }
            
            consumed++;
        }
    }
    
    
    
    if (use_frame && !_video_done)
    {
        if ((use_frame->pts >= _useInput.first_audio_pts) && !_audio_running && !_audio_done)
        {
            [self startAudio];
        }
        
        /*
        if (self.audio_needs_restart)
        {
            [self.pcmPlayer flush];
            [self.pcmPlayer play];
            self.audio_needs_restart = NO;
        }*/
        
        
        self.lastVideoTime = use_frame->pts * av_q2d(_useInput.videoTimeBase);
        
        ret = [self convertFrameToPixelBuffer:use_frame];

        CVPixelBufferRetain(ret);
        if (_last_buf)
        {
            CVPixelBufferRelease(_last_buf);
        }
        _last_buf = ret;
    } else {
        CVPixelBufferRetain(_last_buf);
        ret = _last_buf;
    }
    if (use_frame)
    {
        av_frame_unref(use_frame);
        av_frame_free(&use_frame);
    }
    [self inputDone];
    return ret;
}

-(void)inputDone
{
    
    if (_audio_done && _video_done)
    {

        //[self.currentlyPlaying stop];
        
        if (_forceNextInput)
        {
            [self preChangeItem];
            [self playItem:_forceNextInput];
            _forceNextInput = nil;
        } else if (_doneDirection > 0) {
            [self nextItem];
        } else if (_doneDirection < 0) {
            [self previousItem];
        }
        
    }
}


-(bool) createPixelBufferPoolForSize:(NSSize) size
{
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setValue:@{(NSString *)kIOSurfaceIsGlobal: @NO} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    
    
    if (_cvpool)
    {
        CVPixelBufferPoolRelease(_cvpool);
    }
    
    
    
    CVReturn result = CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(attributes), &_cvpool);
    
    if (result != kCVReturnSuccess)
    {
        return NO;
    }
    
    return YES;
    
    
}

-(CVPixelBufferRef) convertFrameToPixelBuffer:(AVFrame *)av_frame
{
    if (!av_frame || !av_frame->data[0])
    {
        return nil;
    }
    
    
    NSSize frameSize = NSMakeSize(av_frame->width, av_frame->height);
    if (!NSEqualSizes(_currentSize, frameSize))
    {
        _currentSize = frameSize;
        [self createPixelBufferPoolForSize:frameSize];
    }
    
    
    CVPixelBufferRef buf;
    CVPixelBufferPoolCreatePixelBuffer(NULL, _cvpool, &buf);
    
    size_t pbcnt = CVPixelBufferGetPlaneCount(buf);
    
    CVPixelBufferLockBaseAddress(buf, 0);

    for (int i = 0; i < pbcnt; i++)
    {
        uint8_t *src_addr;
        uint8_t *dst_addr;
        size_t dst_stride, src_stride;
        size_t rows;
        
        dst_addr = CVPixelBufferGetBaseAddressOfPlane(buf, i);
        src_addr = av_frame->data[i];
        dst_stride = CVPixelBufferGetBytesPerRowOfPlane(buf, i);
        src_stride = av_frame->linesize[i];
        rows = CVPixelBufferGetHeightOfPlane(buf, i);
        
        if (dst_stride == src_stride)
        {
            memcpy(dst_addr, src_addr, src_stride * rows);
        } else {
            size_t copy_bytes = dst_stride < src_stride ? dst_stride : src_stride;
            for (int j = 0; j < rows; j++)
            {
                memcpy(dst_addr + j * dst_stride, src_addr + j * src_stride, copy_bytes);
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(buf, 0);

    return buf;
}


-(void)removeInputQueueAtIndexes:(NSIndexSet *)indexes
{
    [self.inputQueue removeObjectsAtIndexes:indexes];
    if (self.queueStateChanged)
    {
        self.queueStateChanged();
    }
}

-(void)dealloc
{
    
    if (self.currentlyPlaying)
    {
        [self.currentlyPlaying closeMedia];
    }
    
    for (CSFFMpegInput *item in self.inputQueue)
    {
        [item closeMedia];
    }
    
    if (_peek_frame)
    {
        av_frame_unref(_peek_frame);
        av_frame_free(&_peek_frame);
    }
    
    if (_last_buf)
    {
        CVPixelBufferRelease(_last_buf);
    }
    
    
    if (_cvpool)
    {
        CVPixelBufferPoolFlush(_cvpool, 0);
        CVPixelBufferPoolRelease(_cvpool);
    }
    
}


@end
