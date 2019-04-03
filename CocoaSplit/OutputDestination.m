//
//  OutputDestination.m
//  H264Streamer
//
//  Created by Zakk on 9/16/12.
//

#import "OutputDestination.h"
#import "CSOutputBase.h"
#import "CapturedFrameData.h"

@implementation OutputDestination


@synthesize name = _name;
@synthesize output_format = _output_format;
@synthesize assignedLayout = _assignedLayout;


-(instancetype)copyWithZone:(NSZone *)zone
{
    OutputDestination *newCopy = [[OutputDestination alloc] init];
    newCopy.name = self.name;
    newCopy.type_name = self.type_name;
    newCopy.type_class_name = self.type_class_name;
    newCopy.active = self.active;
    newCopy.stream_delay = self.stream_delay;
    newCopy.compressor_name = self.compressor_name;
    newCopy.streamServiceObject = self.streamServiceObject;
    newCopy->_destination = _destination;
    return newCopy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.type_name forKey:@"type_name"];
    [aCoder encodeObject:self.type_class_name forKey:@"type_class_name"];
    [aCoder encodeBool:self.active forKey:@"active"];
    [aCoder encodeInteger:self.stream_delay forKey:@"stream_delay"];
    [aCoder encodeObject:self.compressor_name forKey:@"compressor_name"];
    [aCoder encodeObject:self.streamServiceObject forKey:@"streamServiceObject"];
    [aCoder encodeObject:_destination forKey:@"destination"];
    [aCoder encodeBool:self.autoRetry forKey:@"autoRetry"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    if (self.assignedLayout)
    {
        [aCoder encodeObject:self.assignedLayout forKey:@"assignedLayout"];
    }
    
    [aCoder encodeObject:self.audioTracks forKey:@"audioTracks"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        
        if ([aDecoder containsValueForKey:@"assignedLayout"])
        {
            self.assignedLayout = [aDecoder decodeObjectForKey:@"assignedLayout"];
        }
        
        if ([aDecoder containsValueForKey:@"uuid"])
        {
            self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        }
        
        _destination = [aDecoder decodeObjectForKey:@"destination"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.type_name = [aDecoder decodeObjectForKey:@"type_name"];
        self.stream_delay = (int)[aDecoder decodeIntegerForKey:@"stream_delay"];
        self.compressor_name = [aDecoder decodeObjectForKey:@"compressor_name"];
        self.streamServiceObject = [aDecoder decodeObjectForKey:@"streamServiceObject"];
        self.type_class_name = [aDecoder decodeObjectForKey:@"type_class_name"];
        self.autoRetry = [aDecoder decodeBoolForKey:@"autoRetry"];
        _active = [aDecoder decodeBoolForKey:@"active"];
        NSDictionary *audioTracks = [aDecoder decodeObjectForKey:@"audioTracks"];
        if (audioTracks)
        {
            self.audioTracks = audioTracks;
        }

    }
    return self;
}




-(id)init
{
    
    return [self initWithType:nil];
    
}


-(SourceLayout *)assignedLayout
{
    return _assignedLayout;
}

-(void)setAssignedLayout:(SourceLayout *)assignedLayout
{
    _assignedLayout = assignedLayout;
    self.audioTracks = [NSMutableDictionary dictionary];
    CAMultiAudioEngine *useEngine = self.audioEngine;
    if (useEngine)
    {
        CAMultiAudioOutputTrack *defTrack = useEngine.defaultOutputTrack;
        if (defTrack)
        {
            self.audioTracks[defTrack.uuid] = defTrack;
        }
    }
}

-(void)stopCompressor
{
    if (self.compressor)
    {
        [self.compressor removeOutput:self];
    }
}



-(NSString *)destination
{
    
    if (_destination)
    {
        return _destination;
    }
    
    return [self.streamServiceObject getServiceDestination];
}



-(NSString *)name
{
    if (_name)
    {
        return _name;
    }
    
    return self.destination;
    
    
}


-(void) setName:(NSString *)name
{
    _name = name;
}



-(void) setup
{
    
    if (!_output_queue)
    {
        NSString *queue_name = [NSString stringWithFormat:@"Output Queue %@", self.name];
        _output_queue = dispatch_queue_create(queue_name.UTF8String, NULL);
    }

    if (self.errored)
    {
        [CaptureController.sharedCaptureController postNotification:CSNotificationOutputRestarted forObject:self];
   }

    self.errored = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusImage = [NSImage imageNamed:@"ok"];
    });

    [self initStatsValues];
    [self setupCompressor];
}

-(void) teardown
{
    [self stopCompressor];
    [self reset];

}
-(void) setActive:(BOOL)is_active
{
    
    bool streamingActive = [CaptureController sharedCaptureController].captureRunning;
    
    bool old_active = _active;
    _active = is_active;

    if (old_active != is_active)
    {
        if (is_active)
        {
            
            if (self.assignedLayout && ![self.assignedLayout isEqual:[NSNull null]] && streamingActive)
            {
                [[CaptureController sharedCaptureController] startRecordingLayout:self.assignedLayout usingOutput:self];
            } else {
                [self setup];
            }
            [CaptureController.sharedCaptureController postNotification:CSNotificationOutputSetActive forObject:self];
       } else {
            
            if (self.assignedLayout && ![self.assignedLayout isEqual:[NSNull null]] && streamingActive)
            {
                [[CaptureController sharedCaptureController] stopRecordingLayout:self.assignedLayout usingOutput:self ];
            } else {
                [self teardown];
            }
            
           [CaptureController.sharedCaptureController postNotification:CSNotificationOutputSetInactive forObject:self];
        }
    }

    

}


-(BOOL) active
{
    return _active;
}




-(void) reset
{
    _output_prepared = NO;
    
    self.buffer_draining = NO;
    [_delayBuffer removeAllObjects];
    [self initStatsValues];
    if (self.ffmpeg_out)
    {
        if (self.errored)
        {
            [self.ffmpeg_out stopProcess];
            self.ffmpeg_out = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusImage = [NSImage imageNamed:@"Record_Icon"];
            });
        } else {
                @autoreleasepool {
                
                [self.ffmpeg_out stopProcess];
                self.ffmpeg_out = nil;
                }
            [CaptureController.sharedCaptureController postNotification:CSNotificationOutputStopped forObject:self];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusImage = [NSImage imageNamed:@"inactive"];
                });
                
        }

    }
    
    _output_start_time = 0.0f;
    
    
}


-(void) stopOutput
{

    if (self.stream_delay > 0 && [_delayBuffer count] > 0 && self.ffmpeg_out)
    {
        self.buffer_draining = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusImage = [NSImage imageNamed:@"draining"];
        });
        return;
    }
    
    
   // if (self.active)
    {
        [self reset];
        [self stopCompressor];
    }
}


-(id) initWithType:(NSString *)type
{
    if (self = [super init])
    {
        
        self.type_name = type;
        self.statusImage = [NSImage imageNamed:@"inactive"];
        _output_start_time = 0.0f;
        _delayBuffer = [[NSMutableArray alloc] init];
        self.delay_buffer_frames = 0;
        _stopped = YES;
        _uuid = [NSUUID UUID].UUIDString;
        self.audioTracks = [NSMutableDictionary dictionary];
        self.assignedLayout = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(compressorDeleted:) name:CSNotificationCompressorDeleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(compressorRenamed:) name:CSNotificationCompressorRenamed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioTrackDeleted:) name:CSNotificationAudioTrackDeleted object:nil];
    }
    return self;
    
    
}

-(void)setOutput_format:(NSString *)output_format
{
    _output_format = output_format;
}


-(NSString *)output_format
{
    if (_output_format)
    {
        return _output_format;
    }
    
    
    if (self.streamServiceObject)
    {
        if ([self.streamServiceObject respondsToSelector:@selector(getServiceFormat)])
        {
            return [self.streamServiceObject getServiceFormat];
        }
    }
    
    return nil;
}


-(void)audioTrackDeleted:(NSNotification *)notification
{
    NSString *trackName = notification.object;
    
    [self removeAudioTrack:trackName];
}



-(void)compressorDeleted:(NSNotification *)notification
{
    id <VideoCompressor> compressor = notification.object;
    
    if (self.compressor_name && [self.compressor_name isEqualToString:compressor.name])
    {
        self.compressor_name = nil;
        self.compressor = nil;
    }
}


-(void)compressorRenamed:(NSNotification *)notification
{
    
    NSDictionary *infoDict = notification.userInfo;
    
    NSString *oldName = infoDict[@"oldName"];
    id <VideoCompressor> compressor = notification.object;
    
    if (self.compressor_name && [self.compressor_name isEqualToString:oldName])
    {
        self.compressor_name = compressor.name;
        self.compressor = compressor;
    }
}


-(void) attachOutput
{
    NSObject<CSOutputWriterProtocol> *newout;
    if (!self.active)
    {
        return;
    }
    
    if (!self.ffmpeg_out)
    {
        if (self.streamServiceObject)
        {
            newout = [self.streamServiceObject createOutput];
            if (!newout)
            {
                newout = [[CSOutputBase alloc] init];
            }
        } else {
            newout = [[CSOutputBase alloc] init];
        }
    } else {
        newout = self.ffmpeg_out;
    }
    
    if (!_output_prepared)
    {
        [self.streamServiceObject prepareForStreamStart];
        _output_prepared = YES;
    }
    
    NSString *destination = self.destination;
    
    if (!destination)
    {
        return;
    }
    
    
    newout.framerate = self.settingsController.frameRate;
    newout.stream_output = [destination stringByStandardizingPath];
    newout.stream_format = self.output_format;
    newout.samplerate = [CaptureController sharedCaptureController].multiAudioEngine.sampleRate;
    newout.audio_bitrate = [CaptureController sharedCaptureController].multiAudioEngine.audioBitrate;
    newout.activeAudioTracks = self.audioTracks;
    
    
    
    self.ffmpeg_out = newout;
    

    

}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    NSImage *newImage = nil;
    
    if ([keyPath isEqualToString:@"errored"]) {
        
        BOOL errVal = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if (errVal == YES)
        {
            self.errored = YES;
            newImage = [NSImage imageNamed:@"Record_Icon"];
            [CaptureController.sharedCaptureController postNotification:CSNotificationOutputErrored forObject:self];
        }
        
    }
    
    
    if (newImage)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusImage = newImage;
        });
    }
    
}

-(void) setupCompressor
{
    if (!self.active || !self.captureRunning)
    {
        return;
    }
    
    NSObject <VideoCompressor> *old_compressor = self.compressor;

    if (self.compressor_name)
    {
        self.compressor = [self.settingsController compressorByName:self.compressor_name];
    }
    
    

    if (self.compressor)
    {
        [self.compressor addOutput:self];
        [self.compressor addObserver:self forKeyPath:@"errored" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    if (old_compressor && (self.compressor != old_compressor))
    {
        [old_compressor removeOutput:self];
        [old_compressor removeObserver:self forKeyPath:@"errored"];
    }
}



-(bool) resetOutputIfNeeded
{
    
    if (self.ffmpeg_out && self.ffmpeg_out.errored)
    {
        return YES;
    }
    
    if ([CaptureController sharedCaptureController].maxOutputDropped)
    {
        if (_consecutive_dropped_frames >= [CaptureController sharedCaptureController].maxOutputDropped)
        {
            return YES;
        }
    }
    return NO;
}


-(bool) shouldDropFrame
{
    if ([CaptureController sharedCaptureController].maxOutputPending)
    {
        if ([self.ffmpeg_out frameQueueSize] >= [CaptureController sharedCaptureController].maxOutputPending)
        {
            return YES;
        }
    }
    
    return NO;
}


-(void) writeEncodedData:(CapturedFrameData *)frameData
{
    
    CapturedFrameData *sendData = nil;
    
    double current_time = [[CaptureController sharedCaptureController] mach_time_seconds];
    
    
    if (self.active)
    {
        

        if (self.stream_delay > 0 && _output_start_time == 0.0f && frameData)
        {
            _output_start_time = current_time + (double)self.stream_delay;
        }
        
        
        if (frameData && self.stream_delay > 0)
        {
            [_delayBuffer addObject:frameData];
        }
        
        
        BOOL start_stream = NO;
        
        if (self.captureRunning && !self.ffmpeg_out)
        {
            
            if (self.stream_delay == 0)
            {
                start_stream = YES;
            }
            
            if ((current_time >= _output_start_time) && ([_delayBuffer count] > 0))
            {
                
                start_stream = YES;
            }
        }
        
        if (start_stream)
        {
            [self attachOutput];
            [CaptureController.sharedCaptureController postNotification:CSNotificationOutputStarted forObject:self];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusImage  = [NSImage imageNamed:@"ok"];
            });
        }
        
        if (frameData)
        {
            _p_input_framecnt++;
            CFTimeInterval frameDelay = current_time - frameData.frameTime;
            _compressor_delay_total += frameDelay;
        }
        
        
        if (self.ffmpeg_out)
        {
            if (_delayBuffer.count > 0)
            {
                sendData = [_delayBuffer objectAtIndex:0];
                [_delayBuffer removeObjectAtIndex:0];
            } else {
                sendData = frameData;
            }
        }

        if (sendData && self.ffmpeg_out)
        {
            
            if ([self resetOutputIfNeeded])
            {
                self.errored = YES;
                self.active = NO;
                [CaptureController.sharedCaptureController postNotification:CSNotificationOutputErrored forObject:self];
                if (self.autoRetry)
                {
                    self.active = YES;
                }
                return;
            }
            
            if ([self shouldDropFrame])
            {
                _dropped_frame_count++;
                _consecutive_dropped_frames++;
            } else {
                _consecutive_dropped_frames = 0;
                [self.ffmpeg_out queueFramedata:sendData];
            }
        }
        
        if (self.buffer_draining)
        {
            if ([_delayBuffer count] <= 0)
            {
                [self stopOutput];
            }
        }
    }

}

-(void) initStatsValues
{
    CFAbsoluteTime time_now = CFAbsoluteTimeGetCurrent();
    _input_frame_timestamp = time_now;
    _output_frame_timestamp = time_now;
    _p_input_framecnt = 0;
    _p_buffered_frame_count = 0;
    _p_buffered_frame_size = 0;
    _p_dropped_frame_count = 0;
    _p_output_framecnt = 0;
    _p_output_bytes = 0;
    _consecutive_dropped_frames = 0;
    _compressor_delay_total = 0.0f;
}


-(CAMultiAudioEngine *)audioEngine
{
    CAMultiAudioEngine *useEngine = nil;
    if (self && self.assignedLayout)
    {
        useEngine = self.assignedLayout.audioEngine;
    } else {
        useEngine = [CaptureController sharedCaptureController].multiAudioEngine;
    }
    
    return useEngine;
}
-(void) updateStatistics
{
    
    CFAbsoluteTime time_now = CFAbsoluteTimeGetCurrent();
    
    int f_output_framecnt;
    NSUInteger f_output_bytes;
    
    f_output_framecnt = self.ffmpeg_out.output_framecnt;
    f_output_bytes = self.ffmpeg_out.output_bytes;
    
    double calculated_input_framerate = _p_input_framecnt / (time_now - _input_frame_timestamp);
    double calculated_output_framerate = f_output_framecnt / (time_now - _output_frame_timestamp);
    double calculated_output_bitrate = (f_output_bytes / (time_now - _output_frame_timestamp)) * 8;
    
    
    
    self.output_framerate = calculated_output_framerate;
    self.input_framerate = calculated_input_framerate;
    self.output_bitrate = calculated_output_bitrate;
    self.buffered_frame_count = self.ffmpeg_out.buffered_frame_count;
    self.buffered_frame_size = self.ffmpeg_out.buffered_frame_size;
    
    if (_p_input_framecnt > 0)
    {
        self.average_compressor_delay = _compressor_delay_total / _p_input_framecnt;
    }
    
    //TODO
    self.dropped_frame_count = _dropped_frame_count;
    self.delay_buffer_frames = [_delayBuffer count];
    _compressor_delay_total = 0.0f;
    _p_input_framecnt = 0;
    _p_output_framecnt = 0;
    _output_frame_timestamp = time_now;
    _input_frame_timestamp = time_now;
    _p_output_bytes = 0;

    
    [self.ffmpeg_out initStatsValues];
    
}



-(NSString *)description
{
    
    return [NSString stringWithFormat:@"Name: %@ Type Name: %@ Destination %@ Key %@", self.name, self.type_name, self.destination, self.stream_key];
    
}

-(void)addAudioTrack:(CAMultiAudioOutputTrack *)outputTrack
{
    [self willChangeValueForKey:@"audioTracks"];
    self.audioTracks[outputTrack.uuid] = outputTrack;
    [self didChangeValueForKey:@"audioTracks"];
    [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackOutputAttached forObject:self];
}


-(void)removeAudioTrack:(CAMultiAudioOutputTrack *)track;
{
    [self willChangeValueForKey:@"audioTracks"];
    [self.audioTracks removeObjectForKey:track.uuid];
    [self didChangeValueForKey:@"audioTracks"];
    [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackOutputDetached forObject:self];
}



-(void)dealloc
{
    [self stopCompressor];
    
    if (self.ffmpeg_out)
    {
        [self.compressor removeObserver:self forKeyPath:@"errored" context:NULL];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end


