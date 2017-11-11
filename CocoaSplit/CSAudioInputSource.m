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
#import "CAMultiAudioFile.h"


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



-(instancetype) initWithPath:(NSString *)path
{
    if (self = [self init])
    {
        self.audioUUID = path;
        self.audioVolume = 0;
        self.name = [path lastPathComponent];
        self.audioEnabled = NO;
        self.audioFilePath = path;
        self.fileDuration = [CAMultiAudioFile durationForPath:path];
        self.fileEndTime = self.fileDuration;
        self.fileStartTime = 0.0f;
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
        if ([node isKindOfClass:CAMultiAudioFile.class])
        {
            self.audioFilePath = ((CAMultiAudioFile *)node).filePath;
        }
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
    [aCoder encodeObject:self.audioFilePath forKey:@"audioFilePath"];
    [aCoder encodeFloat:self.fileStartTime forKey:@"fileStartTime"];
    [aCoder encodeFloat:self.fileEndTime forKey:@"fileEndTime"];
    [aCoder encodeBool:self.fileLoop forKey:@"fileLoop"];
    if (self.audioNode)
    {
        NSMutableDictionary *nodeData = [NSMutableDictionary dictionary];
        [self.audioNode saveDataToDict:nodeData];
        [aCoder encodeObject:nodeData forKey:@"savedAudioSettings"];
    }

}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super initWithCoder:aDecoder])
    {
        self.audioUUID = [aDecoder decodeObjectForKey:@"audioUUID"];
        self.audioVolume = [aDecoder decodeFloatForKey:@"audioVolume"];
        self.audioEnabled = [aDecoder decodeBoolForKey:@"audioEnabled"];
        
        self.audioFilePath = [aDecoder decodeObjectForKey:@"audioFilePath"];
        
        if (self.audioFilePath)
        {
            self.fileDuration = [CAMultiAudioFile durationForPath:self.audioFilePath];
        }

        if ([aDecoder containsValueForKey:@"fileStartTime"])
        {
            self.fileStartTime = [aDecoder decodeFloatForKey:@"fileStartTime"];
        } else {
            self.fileStartTime = 0.0f;
        }
        if ([aDecoder containsValueForKey:@"fileEndTime"])
        {
            self.fileEndTime = [aDecoder decodeFloatForKey:@"fileEndTime"];
        } else {
            self.fileEndTime = self.fileDuration;
        }

        if ([aDecoder containsValueForKey:@"fileLoop"])
        {
            self.fileLoop = [aDecoder decodeBoolForKey:@"fileLoop"];
        } else {
            self.fileLoop = NO;
        }
        
        if ([aDecoder containsValueForKey:@"savedAudioSettings"])
        {
            _savedAudioSettings = [aDecoder decodeObjectForKey:@"savedAudioSettings"];
        }

        
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



-(CAMultiAudioEngine *)findAudioEngine
{
    CAMultiAudioEngine *audioEngine = nil;
    if (self.sourceLayout.recorder)
    {
        audioEngine = self.sourceLayout.recorder.audioEngine;
    } else {
        audioEngine = [CaptureController sharedCaptureController].multiAudioEngine;
    }
    
    return audioEngine;
}
-(void)findAudioNode
{
    
    if (!self.audioNode && self.audioUUID && self.sourceLayout)
    {
        CAMultiAudioEngine *audioEngine = [self findAudioEngine];
        self.audioNode = [audioEngine inputForUUID:self.audioUUID];
        
        if (!self.audioNode && self.audioFilePath)
        {
            self.audioNode = [[CAMultiAudioFile alloc] initWithPath:self.audioFilePath];
            //Tell the audio engine not to save or restore settings for this input
            if (self.audioNode)
            {
                self.audioNode.noSettings = YES;
                [audioEngine addFileInput:self.audioNode];
            }
        }
    }
}


-(void)applyAudioSettings
{
    if (!self.audioNode)
    {
        [self findAudioNode];
        if (self.audioNode && [self.audioNode isKindOfClass:CAMultiAudioFile.class])
        {
            
            ((CAMultiAudioFile *)self.audioNode).refCount++;
        }
        
        
        _previousSaveData = [NSMutableDictionary dictionary];
        [self.audioNode saveDataToDict:_previousSaveData];
        //_previousVolume = self.audioNode.volume;
        //_previousEnabled = self.audioNode.enabled;
        


    }

    if (self.audioNode)
    {
        if ([self.audioNode isKindOfClass:CAMultiAudioFile.class])
        {
            CAMultiAudioFile *fileNode = (CAMultiAudioFile *)self.audioNode;
            fileNode.loop = self.fileLoop;
            fileNode.startTime = self.fileStartTime;
            fileNode.endTime = self.fileEndTime;
        }
        
        self.audioEnabled = self.audioEnabled;
        self.audioVolume = self.audioVolume;
        
        if (_savedAudioSettings)
        {
                if (self.is_live)
                {
                    [self.audioNode restoreDataFromDict:_savedAudioSettings];
                }
        }


    }
}

-(void)restoreAudioSettings
{
    
    if (self.audioNode && self.is_live && _previousSaveData)
    {
        
        [self.audioNode restoreDataFromDict:_previousSaveData];
        //self.audioNode.enabled = _previousEnabled;
        //self.audioNode.volume = _previousVolume;
    }
    
    if ([self.audioNode isKindOfClass:CAMultiAudioFile.class])
    {
        CAMultiAudioFile *fileNode = (CAMultiAudioFile *)self.audioNode;
        fileNode.refCount--;
        
        if (fileNode.refCount <= 0)
        {
            [[self findAudioEngine] removeFileInput:fileNode];
        }
    }

}

-(float)duration
{
    return self.fileEndTime - self.fileStartTime;
}


/*
-(void)afterReplace
{
    NSLog(@"AFTER REPLACE");
    [self applyAudioSettings];

}
 
-(void)afterAdd
{
    NSLog(@"AFTER ADD");
    [self applyAudioSettings];
}


-(void)afterMerge:(bool)changed
{
   // if (changed)
    {
        
        [self findAudioNode];
    }
    
    if (self.audioNode && [self.audioNode isKindOfClass:CAMultiAudioFile.class])
    {
        
        ((CAMultiAudioFile *)self.audioNode).refCount++;

    }

    
    

}
 */

-(void)beforeReplace:(bool)removing
{
    if (removing)
    {
        [self restoreAudioSettings];

    }
}


-(void)beforeRemove
{
    
    [self restoreAudioSettings];
    if ([self.audioNode isKindOfClass:CAMultiAudioFile.class])
    {

        
        [[self findAudioEngine] removeFileInput:(CAMultiAudioFile *)self.audioNode];
    }
}

-(bool)isDifferentInput:(NSObject<CSInputSourceProtocol> *)from
{
    if ([from isKindOfClass:self.class])
    {
        CSAudioInputSource *fromAudio = (CSAudioInputSource *)from;
        return ![self.audioUUID isEqualToString:fromAudio.audioUUID];
    }
    
    return [super isDifferentInput:from];
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
