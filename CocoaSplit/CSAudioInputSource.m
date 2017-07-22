//
//  CSAudioInputSource.m
//  CocoaSplit
//
//  Created by Zakk on 7/5/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSAudioInputSource.h"
#import "CSAudioInputSourceViewController.h"
#import "CaptureController.h"
#import "CSLayoutRecorder.h"

@implementation CSAudioInputSource
@synthesize audioUUID = _audioUUID;
@synthesize audioEnabled = _audioEnabled;
@synthesize audioVolume = _audioVolume;

-(instancetype) init
{
    if (self = [super init])
    {
        [self createUUID];
        self.active = YES;
    }
    
    return self;
}



-(instancetype) initWithAudioNode:(CAMultiAudioNode *)node
{
    if (self = [self init])
    {
        self.audioUUID = node.nodeUID;
        self.audioVolume = node.volume;
        self.name = node.name;
        self.audioEnabled = node.enabled;
    }
    
    return self;
}
-(instancetype)copyWithZone:(NSZone *)zone
{
    CSAudioInputSource *newCopy = [super copyWithZone:zone];
    newCopy.audioUUID = self.audioUUID;
    newCopy.audioVolume = self.audioVolume;
    newCopy.audioEnabled = self.audioEnabled;
    return newCopy;
}



-(NSString *)label
{
    return @"Audio";
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.audioUUID forKey:@"audioUUID"];
    [aCoder encodeFloat:self.audioVolume forKey:@"audioVolume"];
    [aCoder encodeBool:self.audioEnabled forKey:@"audioEnabled"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super initWithCoder:aDecoder])
    {
        self.audioUUID = [aDecoder decodeObjectForKey:@"audioUUID"];
        self.audioVolume = [aDecoder decodeFloatForKey:@"audioVolume"];
        self.audioEnabled = [aDecoder decodeBoolForKey:@"audioEnabled"];
    }
    
    return self;
}


-(NSImage *)libraryImage
{
    return [NSImage imageNamed:@"Speaker_Icon"];
}


-(NSViewController *)configurationViewController
{
    CSAudioInputSourceViewController *controller = [[CSAudioInputSourceViewController alloc] init];
    controller.inputSource = self;
    return controller;
}


-(float)audioVolume
{
    return _audioVolume;
}

-(void)setAudioVolume:(float)audioVolume
{
    _audioVolume = audioVolume;
    if (self.is_live && self.audioNode)
    {
        self.audioNode.volume = audioVolume;
    }
}


-(bool)audioEnabled
{
    return _audioEnabled;
}

-(void)setAudioEnabled:(bool)audioEnabled
{
    
    if (self.is_live && self.audioNode)
    {
        self.audioNode.enabled = audioEnabled;
    }
    _audioEnabled = audioEnabled;
}

-(void)applyAudioSettings
{
    if (!self.audioNode && self.audioUUID && self.sourceLayout)
    {
        
        CAMultiAudioEngine *audioEngine = nil;
        if (self.sourceLayout.recorder)
        {
            audioEngine = self.sourceLayout.recorder.audioEngine;
        } else {
            audioEngine = [CaptureController sharedCaptureController].multiAudioEngine;
        }
        
        self.audioNode = [audioEngine inputForUUID:self.audioUUID];
        _previousVolume = self.audioNode.volume;
        _previousEnabled = self.audioNode.enabled;

    }

    if (self.audioNode)
    {
        self.audioEnabled = self.audioEnabled;
        self.audioVolume = self.audioVolume;

    }
}

-(void)restoreAudioSettings
{
    
    if (self.audioNode && self.is_live)
    {
        self.audioNode.enabled = _previousEnabled;
        self.audioNode.volume = _previousVolume;
    }

}

-(void)afterAdd
{
        [self applyAudioSettings];
}

-(void)afterMerge:(bool)changed
{
    if (changed)
    {
        [self afterAdd];
    }
}

-(void)beforeReplace
{
    NSLog(@"BEFORE REPLACE %@ %d", self.audioNode, self.is_live);
    [self restoreAudioSettings];
}


-(void)beforeRemove
{
    [self restoreAudioSettings];
}


-(void)setIs_live:(bool)is_live
{
    [super setIs_live:is_live];
    if (is_live)
    {
        [self applyAudioSettings];
    }
}

@end
