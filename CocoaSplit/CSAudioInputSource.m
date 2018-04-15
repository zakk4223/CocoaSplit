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



-(void)setSourceLayout:(SourceLayout *)sourceLayout
{
    [super setSourceLayout:sourceLayout];
    CAMultiAudioEngine *myEngine = [self findAudioEngine];
    if (myEngine)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioNotification:) name:CSNotificationAudioAdded object:myEngine];
    }
}

-(void)audioNotification:(NSNotification *)notification
{
    NSDictionary *userData = notification.userInfo;
    NSString *nodeUUID = userData[@"UUID"];
    if (nodeUUID && [nodeUUID isEqualToString:self.audioUUID])
    {
        [self applyAudioSettings];
    }
}


-(NSString *)label
{
    return @"Audio";
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.name forKey:@"name"];

    [aCoder encodeObject:self.audioUUID forKey:@"audioUUID"];
    [aCoder encodeFloat:self.audioVolume forKey:@"audioVolume"];
    [aCoder encodeBool:self.audioEnabled forKey:@"audioEnabled"];
    [aCoder encodeObject:self.audioFilePath forKey:@"audioFilePath"];
    [aCoder encodeFloat:self.fileStartTime forKey:@"fileStartTime"];
    [aCoder encodeFloat:self.fileEndTime forKey:@"fileEndTime"];
    [aCoder encodeBool:self.fileLoop forKey:@"fileLoop"];
    NSLog(@"ENCODING WITH CODER %@", self.audioNode);
    if (self.audioNode)
    {
        NSMutableDictionary *nodeData = [NSMutableDictionary dictionary];
        [self.audioNode saveDataToDict:nodeData];
        NSLog(@"NODE DATA %@", nodeData);
        [aCoder encodeObject:nodeData forKey:@"savedAudioSettings"];
    } else if (_savedAudioSettings) {
        [aCoder encodeObject:_savedAudioSettings forKey:@"savedAudioSettings"];
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
    if (self.audioNode)
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
    
    if (self.audioNode)
    {
        self.audioNode.enabled = audioEnabled;
    }
    _audioEnabled = audioEnabled;
}



-(CAMultiAudioEngine *)findAudioEngine
{
    CAMultiAudioEngine *audioEngine = nil;
    audioEngine = [self.sourceLayout findAudioEngine];
    if (!audioEngine)
    {
        audioEngine = [CaptureController sharedCaptureController].multiAudioEngine;
    }
    
    return audioEngine;
}


-(CAMultiAudioInput *)findAudioNodeForEdit
{
    CAMultiAudioInput *returnNode = nil;
    
    if (self.audioNode)
    {
        return self.audioNode;
    }
    CAMultiAudioEngine *audioEngine = [self findAudioEngine];
    CAMultiAudioInput *existingNode = [audioEngine inputForUUID:self.audioUUID];
    
    if (!existingNode && self.audioFilePath)
    {
        existingNode = [[CAMultiAudioFile alloc] initWithPath:self.audioFilePath];
    }
    
    
    if (existingNode)
    {
        returnNode = [[[existingNode class] alloc] init];
        
        [self applyAudioSettingsForNode:returnNode];
        return returnNode;
    }
    return returnNode;
}


-(void)findAudioNode
{
    
    if (!self.audioNode && self.audioUUID && self.sourceLayout)
    {
        CAMultiAudioEngine *audioEngine = [self findAudioEngine];
        self.audioNode = [audioEngine inputForUUID:self.audioUUID];

        if (!self.audioNode)
        {
            self.audioNode = [audioEngine inputForSystemUUID:self.audioUUID];
        }
        
        NSLog(@"AUDIO NODE IS %@", self.audioNode);
        if (!self.audioNode && self.audioFilePath)
        {
            self.audioNode = [[CAMultiAudioFile alloc] initWithPath:self.audioFilePath];
            //Tell the audio engine not to save or restore settings for this input
            if (self.audioNode)
            {
                self.audioNode.noSettings = YES;
                [audioEngine addFileInput:(CAMultiAudioFile *)self.audioNode];
            }
        }
    }
}

-(void)applyAudioSettingsForNode:(CAMultiAudioInput *)node
{
    if (node)
    {
        if ([node isKindOfClass:CAMultiAudioFile.class])
        {
            CAMultiAudioFile *fileNode = (CAMultiAudioFile *)node;
            fileNode.loop = self.fileLoop;
            fileNode.startTime = self.fileStartTime;
            fileNode.endTime = self.fileEndTime;
        }
        
        node.enabled = self.audioEnabled;
        node.volume = self.audioVolume;
        
        if (_savedAudioSettings)
        {
            [node restoreDataFromDict:_savedAudioSettings];
        }
    }
}

-(void)applyAudioSettings
{
    if (!self.audioNode)
    {
        [self findAudioNode];
        if (self.audioNode)
        {
            
            self.audioNode.refCount++;
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
            [self.audioNode restoreDataFromDict:_savedAudioSettings];
        }


    }
}

-(void)restoreAudioSettings
{
    
    if (self.audioNode  && _previousSaveData)
    {
        
        [self.audioNode restoreDataFromDict:_previousSaveData];
        //self.audioNode.enabled = _previousEnabled;
        //self.audioNode.volume = _previousVolume;
    }
    
    self.audioNode.refCount--;
    if (self.audioNode.refCount <= 0)
    {
        [[self findAudioEngine] removeInputAny:self.audioNode];
    }
}

-(float)duration
{
    return self.fileEndTime - self.fileStartTime;
}



-(bool) isAudio
{
    return YES;
}

-(void)dealloc
{
    [self restoreAudioSettings];
}


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
        //[[self findAudioEngine] removeFileInput:(CAMultiAudioFile *)self.audioNode];
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

-(void)setIsVisible:(bool)isVisible
{
    [super setIsVisible:isVisible];
    if (isVisible)
    {
        [self applyAudioSettings];
    }
}
@end
