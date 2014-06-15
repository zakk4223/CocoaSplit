//
//  OutputDestination.m
//  H264Streamer
//
//  Created by Zakk on 9/16/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "OutputDestination.h"


@implementation OutputDestination




-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [aCoder encodeObject:self.destination forKey:@"destination"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.type_name forKey:@"type_name"];
    [aCoder encodeObject:self.output_format forKey:@"output_format"];
    [aCoder encodeBool:self.active forKey:@"active"];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.destination = [aDecoder decodeObjectForKey:@"destination"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.type_name = [aDecoder decodeObjectForKey:@"type_name"];
        self.output_format = [aDecoder decodeObjectForKey:@"output_format"];
        self.active = [aDecoder decodeBoolForKey:@"active"];
    }
    
    return self;
}



-(id)init
{
    
    return [self initWithType:nil];
    
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
        if (!is_active && self.ffmpeg_out)
        {
            [self.ffmpeg_out stopProcess];
        } else if (is_active && self.ffmpeg_out) {
            [self attachOutput:self.settingsController];
        }
        
    }
}


-(BOOL) active
{
    return _active;
}



-(void)setDestination:(NSString *)destination
{
    
    NSLog(@"Destination set to %@", destination);
    if ([destination hasPrefix:@"rtmp://"] || [destination hasPrefix:@"udp:"])
    {
        self.output_format = @"FLV";
    }
     _destination = destination;
    
}

-(void) stopOutput
{
    if (self.ffmpeg_out && self.active)
    {
        [self.ffmpeg_out stopProcess];
        self.ffmpeg_out = nil;
    }
}


-(id) initWithType:(NSString *)type
{
    if (self = [super init])
    {
        
        self.type_name = type;

        self.textColor = [NSColor blackColor];
    }
    return self;
    
    
}


-(void) attachOutput:(id<ControllerProtocol>) settingsController
{
    FFMpegTask *newout;
    if (!self.ffmpeg_out)
    {
        newout = [[FFMpegTask alloc] init];
    } else {
        newout = self.ffmpeg_out;
    }
    
    self.settingsController = settingsController;
    
    newout.framerate = settingsController.captureFPS;
    newout.stream_output = [self.destination stringByStandardizingPath];
    newout.stream_format = self.output_format;
    newout.settingsController = settingsController;
    newout.active = self.active;
    newout.samplerate = settingsController.audioSamplerate;
    newout.audio_bitrate = settingsController.audioBitrate;
    
    self.ffmpeg_out = newout;
    
    [self.ffmpeg_out addObserver:self forKeyPath:@"errored" options:NSKeyValueObservingOptionNew context:NULL];

}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"errored"])
    {
        
        BOOL errVal = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if (errVal == YES)
        {
            //bounce through main thread because it triggers a notification to the UI and sometimes it won't properly update due to threads HURRRRRRR???
            //this can't be right, it's too...stupid
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textColor = [NSColor redColor];
            });
        }
        
    }
}

-(NSString *)description
{
    
    return [NSString stringWithFormat:@"Name: %@ Type Name: %@ Destination %@ Key %@", self.name, self.type_name, self.destination, self.stream_key];
    
}

-(void)dealloc
{
    if (self.ffmpeg_out)
    {
        [self.ffmpeg_out removeObserver:self forKeyPath:@"errored" context:NULL];
    }

}


@end


