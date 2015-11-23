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


-(instancetype)copyWithZone:(NSZone *)zone
{
    OutputDestination *newCopy = [[OutputDestination alloc] init];
    newCopy.destination = self.destination;
    newCopy.name = self.name;
    newCopy.type_name = self.type_name;
    newCopy.type_class_name = self.type_class_name;
    newCopy.output_format = self.output_format;
    newCopy.active = self.active;
    newCopy.stream_delay = self.stream_delay;
    newCopy.compressor_name = self.compressor_name;
    newCopy.streamServiceObject = self.streamServiceObject;
    return newCopy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [aCoder encodeObject:self.destination forKey:@"destination"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.type_name forKey:@"type_name"];
    [aCoder encodeObject:self.type_class_name forKey:@"type_class_name"];
    [aCoder encodeObject:self.output_format forKey:@"output_format"];
    [aCoder encodeBool:self.active forKey:@"active"];
    [aCoder encodeInteger:self.stream_delay forKey:@"stream_delay"];
    [aCoder encodeObject:self.compressor_name forKey:@"compressor_name"];
    [aCoder encodeObject:self.streamServiceObject forKey:@"streamServiceObject"];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        
        self.destination = [aDecoder decodeObjectForKey:@"destination"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.type_name = [aDecoder decodeObjectForKey:@"type_name"];
        self.output_format = [aDecoder decodeObjectForKey:@"output_format"];
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
        return _destination;
    
    
    if ([_type_name isEqualToString:@"rtmp"])
    {
        _destination = [NSString stringWithFormat:@"%@/%@", self.server_name, self.stream_key];
                
    }
    
    return _destination;
    
}

-(NSString *)name
{
    if (_name)
    {
        return _name;
    }
    
    return _destination;
    
    
}


-(void) setName:(NSString *)name
{
    _name = name;
}


-(void) setActive:(BOOL)is_active
{
    
    if (is_active != _active)
    {
        _active = is_active;
        if (!is_active)
        {
            [self stopCompressor];
            [self reset];
        } else {
            [self setupCompressor];
        }
        
    }
}


-(BOOL) active
{
    return _active;
}



-(void)setDestination:(NSString *)destination
{
    
    if ([destination hasPrefix:@"rtmp://"] || [destination hasPrefix:@"udp:"])
    {
        self.output_format = @"FLV";
    }
     _destination = destination;
    
}


-(void) reset
{
    self.buffer_draining = NO;
    [_delayBuffer removeAllObjects];
    
    if (self.ffmpeg_out)
    {
        [self.ffmpeg_out stopProcess];
        [self.ffmpeg_out removeObserver:self forKeyPath:@"errored"];
        [self.ffmpeg_out removeObserver:self forKeyPath:@"active"];

        
        self.ffmpeg_out = nil;
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


-(void)compressorDeleted:(NSNotification *)notification
{
    id <h264Compressor> compressor = notification.object;
    
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
    id <h264Compressor> compressor = infoDict[@"compressor"];
    
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
    
    
    /*
    if (self.stream_delay > 0)
    {
        _output_start_time = [self.settingsController mach_time_seconds] + self.stream_delay;
    }
    */
    

    newout.framerate = self.settingsController.captureFPS;
    newout.stream_output = [self.destination stringByStandardizingPath];
    newout.stream_format = self.output_format;
    newout.settingsController = self.settingsController;
    newout.samplerate = self.settingsController.audioSamplerate;
    newout.audio_bitrate = self.settingsController.audioBitrate;
    
    
    
    self.ffmpeg_out = newout;
    
    [self.ffmpeg_out addObserver:self forKeyPath:@"errored" options:NSKeyValueObservingOptionNew context:NULL];
    [self.ffmpeg_out addObserver:self forKeyPath:@"active" options:NSKeyValueObservingOptionNew context:NULL];

    self.ffmpeg_out.active = self.active;
    

}

-(void) setupCompressor
{
    if (!self.active)
    {
        return;
    }
    
    NSObject <h264Compressor> *old_compressor = self.compressor;

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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    NSColor *newColor = nil;
    
    if ([keyPath isEqualToString:@"active"])
    {
        BOOL activeVal = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (activeVal == YES)
        {
            newColor = [NSColor greenColor];
        } else {
            newColor = [NSColor blackColor];
        }
        
    } else if ([keyPath isEqualToString:@"errored"]) {
        
        BOOL errVal = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if (errVal == YES)
        {
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
        
        
        if (frameData)
        {
            [_delayBuffer addObject:frameData];
        }
        
        
        
        
        if ((current_time >= _output_start_time) && ([_delayBuffer count] > 0))
        {
            
            
            if (self.settingsController.captureRunning && !self.ffmpeg_out)
            {
                [self attachOutput];
            }
            
            
            sendData = [_delayBuffer objectAtIndex:0];
            [_delayBuffer removeObjectAtIndex:0];
        }
        
        
        if (sendData && self.ffmpeg_out)
        {
            [self.ffmpeg_out writeEncodedData:sendData];
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


-(void) updateStatistics
{
    
    if (self.ffmpeg_out)
    {
        [self.ffmpeg_out updateInputStats];
        [self.ffmpeg_out updateOutputStats];
        self.output_framerate = self.ffmpeg_out.output_framerate;
        self.output_bitrate = self.ffmpeg_out.output_bitrate;
        self.input_framerate = self.ffmpeg_out.input_framerate;
        self.dropped_frame_count = self.ffmpeg_out.dropped_frame_count;
        self.buffered_frame_count = self.ffmpeg_out.buffered_frame_count;
        self.buffered_frame_size = self.ffmpeg_out.buffered_frame_size;
    }
    
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
        [self.ffmpeg_out removeObserver:self forKeyPath:@"errored" context:NULL];
        [self.ffmpeg_out removeObserver:self forKeyPath:@"active" context:NULL];
        [self.compressor removeObserver:self forKeyPath:@"errored" context:NULL];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end


