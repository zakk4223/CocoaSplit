//
//  OutputDestination.m
//  H264Streamer
//
//  Created by Zakk on 9/16/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "OutputDestination.h"
#import "FFMpegTask.h"


@implementation OutputDestination


@synthesize name = _name;
@synthesize output_format = _output_format;



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
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        _destination = [aDecoder decodeObjectForKey:@"destination"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.type_name = [aDecoder decodeObjectForKey:@"type_name"];
        self.active = [aDecoder decodeBoolForKey:@"active"];
        self.stream_delay = (int)[aDecoder decodeIntegerForKey:@"stream_delay"];
        self.compressor_name = [aDecoder decodeObjectForKey:@"compressor_name"];
        self.streamServiceObject = [aDecoder decodeObjectForKey:@"streamServiceObject"];
        self.type_class_name = [aDecoder decodeObjectForKey:@"type_class_name"];
    }
    return self;
}




-(id)init
{
    
    return [self initWithType:nil];
    
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


-(void) setActive:(BOOL)is_active
{
    
    if (!_output_queue)
    {
        NSString *queue_name = [NSString stringWithFormat:@"Output Queue %@", self.name];
        _output_queue = dispatch_queue_create(queue_name.UTF8String, NULL);
    }
    
    
    if (is_active != _active)
    {
        _active = is_active;
        if (!is_active)
        {
            [self stopCompressor];
            [self reset];
        } else {
            [self initStatsValues];
            [self setupCompressor];
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
            //errors jump the queue and just kill the ffmpeg output
            [self.ffmpeg_out stopProcess];
            self.ffmpeg_out = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textColor = [NSColor redColor];
            });
        } else {
            dispatch_async(_output_queue, ^{
                @autoreleasepool {
                
                [self.ffmpeg_out stopProcess];
                self.ffmpeg_out = nil;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.textColor = [NSColor blackColor];
                });
                
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
            self.textColor = [NSColor orangeColor];
        });
        return;
    }
    
    
    if (self.active)
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
        self.textColor = [NSColor blackColor];
        _output_start_time = 0.0f;
        _delayBuffer = [[NSMutableArray alloc] init];
        self.delay_buffer_frames = 0;
        _stopped = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(compressorDeleted:) name:CSNotificationCompressorDeleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(compressorRenamed:) name:CSNotificationCompressorRenamed object:nil];


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
    
    NSDictionary *infoDict = notification.object;
    
    NSString *oldName = infoDict[@"oldName"];
    id <VideoCompressor> compressor = infoDict[@"compressor"];
    
    if (self.compressor_name && [self.compressor_name isEqualToString:oldName])
    {
        self.compressor_name = compressor.name;
        self.compressor = compressor;
    }
}


-(void) attachOutput
{
    FFMpegTask *newout;
    if (!self.active)
    {
        return;
    }
    
    if (!self.ffmpeg_out)
    {
        newout = [[FFMpegTask alloc] init];
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
    
    
    /*
    if (self.stream_delay > 0)
    {
        _output_start_time = [self.settingsController mach_time_seconds] + self.stream_delay;
    }
    */
    
    newout.video_codec_id  = self.compressor.codec_id;
    newout.framerate = self.settingsController.captureFPS;
    newout.stream_output = [destination stringByStandardizingPath];
    newout.stream_format = self.output_format;
    newout.settingsController = self.settingsController;
    newout.samplerate = self.settingsController.audioSamplerate;
    newout.audio_bitrate = self.settingsController.audioBitrate;
    
    
    
    self.ffmpeg_out = newout;
    

    

}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    NSColor *newColor = nil;
    
    if ([keyPath isEqualToString:@"errored"]) {
        
        BOOL errVal = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if (errVal == YES)
        {
            self.errored = YES;
            newColor = [NSColor redColor];
        }
        
    }
    
    
    if (newColor)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textColor = newColor;
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
        self.compressor = self.settingsController.compressors[self.compressor_name];
    }
    
    
    if (!self.compressor)
    {
        NSLog(@"NO COMPRESSOR");
        
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
    if (self.settingsController.maxOutputDropped)
    {
        if (_consecutive_dropped_frames >= self.settingsController.maxOutputDropped)
        {
            return YES;
        }
    }
    return NO;
}


-(bool) shouldDropFrame
{
    if (self.settingsController.maxOutputPending)
    {
        if (_pending_frame_count >= self.settingsController.maxOutputPending)
        {
            return YES;
        }
    }
    
    return NO;
}


-(void) writeEncodedData:(CapturedFrameData *)frameData
{
    
    CapturedFrameData *sendData = nil;
    double current_time = [self.settingsController mach_time_seconds];
    
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
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textColor  = [NSColor greenColor];
            });
        }
        
        if (frameData)
        {
            _p_input_framecnt++;
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
            NSInteger f_size = [sendData encodedDataLength];
            
            if ([self resetOutputIfNeeded])
            {
                self.errored = YES;
                self.active = NO;
                return;
            }
            if ([self shouldDropFrame])
            {
                _dropped_frame_count++;
                _consecutive_dropped_frames++;
            } else {
                _consecutive_dropped_frames = 0;
                
                dispatch_async(_output_queue, ^{
                    @autoreleasepool {
                        _p_buffered_frame_size += f_size;
                        _p_buffered_frame_count++;
                        
                        BOOL write_ret = [self.ffmpeg_out writeEncodedData:sendData];
                        
                        if (write_ret)
                        {
                            _p_output_framecnt++;
                            _p_buffered_frame_count--;
                            _p_buffered_frame_size -= f_size;
                            _p_output_bytes += f_size;
                        }
                    }
                    
                });
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
}


-(void) updateStatistics
{
    
    CFAbsoluteTime time_now = CFAbsoluteTimeGetCurrent();
    
    double calculated_input_framerate = _p_input_framecnt / (time_now - _input_frame_timestamp);
    double calculated_output_framerate = _p_output_framecnt / (time_now - _output_frame_timestamp);
    double calculated_output_bitrate = (_p_output_bytes / (time_now - _output_frame_timestamp)) * 8;
    
    _p_input_framecnt = 0;
    _p_output_framecnt = 0;
    _output_frame_timestamp = time_now;
    _input_frame_timestamp = time_now;
    _p_output_bytes = 0;
    
    
    self.output_framerate = calculated_output_framerate;
    self.input_framerate = calculated_input_framerate;
    self.output_bitrate = calculated_output_bitrate;
    self.buffered_frame_count = _p_buffered_frame_count;
    self.buffered_frame_size = _p_buffered_frame_size;
    //TODO
    self.dropped_frame_count = 0;
    self.delay_buffer_frames = [_delayBuffer count];

}



-(NSString *)description
{
    
    return [NSString stringWithFormat:@"Name: %@ Type Name: %@ Destination %@ Key %@", self.name, self.type_name, self.destination, self.stream_key];
    
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


