//
//  CAMultiAudioInput.m
//  CocoaSplit
//
//  Created by Zakk on 7/30/17.
//

#import "CAMultiAudioInput.h"
#import "CAMultiAudioDelay.h"
#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioEngine.h"
#import "CaptureController.h"

@implementation CAMultiAudioInput
@synthesize delay = _delay;


-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType
{
    if (self = [super initWithSubType:subType unitType:unitType])
    {
        self.isGlobal = NO;
        _delayNodes = [NSMutableArray array];
        self.nameColor = [NSColor blackColor];
        self.powerLevels = [NSMutableDictionary dictionary];
        [self.powerLevels setObject:[NSMutableArray array] forKey:@"input"];
        [self.powerLevels setObject:[NSMutableArray array] forKey:@"output"];
        self.outputTracks = [NSMutableDictionary dictionary];
        
    }
    
    return self;
}


-(void)updatePowerlevel
{
    if (!self.downMixer)
    {
        return;
    }
    
    NSMutableArray *inputArray = self.powerLevels[@"input"];
    NSMutableArray *outputArray = self.powerLevels[@"output"];
    
    if (inputArray.count != self.channelCount)
    {
        if (inputArray.count < self.channelCount)
        {
            
            for (NSUInteger i = 0; i < self.channelCount - inputArray.count; i++)
            {
                [inputArray addObject:@(-240.0f)];
            }
        } else {
            
            for (NSUInteger i = inputArray.count - 1; i >= self.channelCount; i--)
            {
                [inputArray removeObjectAtIndex:i];
            }
        }
    }
    
    if (outputArray.count != self.downMixer.outputChannelCount)
    {
        
        if (outputArray.count < self.downMixer.outputChannelCount)
        {
            for (NSUInteger i = 0; i < self.downMixer.outputChannelCount - outputArray.count; i++)
            {
                [outputArray addObject:@(-240.0f)];
            }
        } else {
            
            for (NSUInteger i = outputArray.count - 1; i >= self.downMixer.outputChannelCount; i--)
            {
                [outputArray removeObjectAtIndex:i];
            }
        }
    }
    

    
    for(int i = 0; i < inputArray.count; i++)
    {
        
        float inPower = [self.downMixer powerForInputBus:i];
        [self.powerLevels[@"input"] replaceObjectAtIndex:i withObject:@(inPower)];
    }

    for (int i = 0; i < outputArray.count; i++)
    {
        float outPower = [self.downMixer powerForOutputBus:i];
        [self.powerLevels[@"output"] replaceObjectAtIndex:i withObject:@(outPower)];
    }
}

-(void)addToOutputTrack:(CAMultiAudioOutputTrack *)outputTrack
{
    [self willChangeValueForKey:@"outputTracks"];
    [self.engine addInput:self toTrack:outputTrack];
    [self didChangeValueForKey:@"outputTracks"];
    [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackInputAdded forObject:self];
}


-(void)removeFromOutputTrack:(NSString *)trackUUID
{
    
    
    [self willChangeValueForKey:@"outputTracks"];
    [self.engine removeInput:self fromTrack:trackUUID];
    [self didChangeValueForKey:@"outputTracks"];
    [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackInputDeleted forObject:self];
}

-(bool)teardownGraph
{
    if (!self.graph)
    {
        //!?!?!
        return NO;
    }
    
    
    if (self.converterNode)
    {
        [self.graph removeNode:self.converterNode];
    }
    
    if (self.downMixer)
    {
        [self.graph removeNode:self.downMixer];
    }
    
    NSArray *delayNodes = self.delayNodes.copy;
    for (CAMultiAudioDelay *dNode in delayNodes)
    {
        [self.graph removeNode:dNode];
        [self.delayNodes removeObject:dNode];
    }
    

    self.converterNode = nil;
    self.downMixer = nil;
    self.headNode = nil;
    return YES;
}


-(bool)setupGraph
{
    

    if (!self.converterNode)
    {
        self.converterNode = [[CAMultiAudioConverter alloc] init];
    }
    
    if (![self.graph addNode:self.converterNode])
    {
        [self teardownGraph];
        return NO;
    }
    


    if (![self.graph connectNode:self toNode:self.converterNode  format:self.inputFormat])
    {
        [self teardownGraph];
        return NO;
    }
    
    AVAudioFormat *useFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:self.graph.audioFormat.sampleRate channelLayout:self.inputFormat.channelLayout];
    CAMultiAudioDelay *delayNode;
    CAMultiAudioNode *connectNode = self.converterNode;
    for(int i=0; i < 5; i++)
    {

        bool ret;
        
        delayNode = [[CAMultiAudioDelay alloc] init];
        ret = [self.graph addNode:delayNode];
        if (!ret)
        {
            [self teardownGraph];
            return NO;
        }
        ret = [self.graph connectNode:connectNode toNode:delayNode format:useFormat];
        if (!ret)
        {
            
            [self.graph removeNode:delayNode];
            [self teardownGraph];
            return NO;
        }
        

        connectNode = delayNode;
        delayNode.bypass = YES;
        [self.delayNodes addObject:delayNode];
    }
    
    self.headNode = delayNode;
    self.effectsHead = delayNode;
    return YES;
    
}


-(void)setupDownmixer
{
    AVAudioFormat *useFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:self.graph.audioFormat.sampleRate channelLayout:self.inputFormat.channelLayout];

    
    self.downMixer = [[CAMultiAudioDownmixer alloc] initWithInputChannels:useFormat.channelCount];
    [self.graph addNode:self.downMixer];
    [self.graph connectNode:self.headNode toNode:self.downMixer format:useFormat];
    self.headNode = self.downMixer;
    self.downMixer.volume = 1.0f;
    self.downMixer.muted = NO;
    [self.downMixer connectInputBus:0 toOutputBus:0];

}


-(void)setupEffectsChain
{
    [self setupGraph];
    [super setupEffectsChain];
    [self setupDownmixer];
    
}

-(void)removeEffectsChain
{
    [self teardownGraph];
    [super removeEffectsChain];
}




-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    [super saveDataToDict:saveDict];
    saveDict[@"delay"] = [NSNumber numberWithFloat:self.delay];
    if (self.downMixer)
    {
        saveDict[@"downMixerData"] = [self.downMixer saveData];
    }
    saveDict[@"isGlobal"] = [NSNumber numberWithBool:self.isGlobal];
    saveDict[@"outputTracksUUIDs"] = self.outputTracks.allKeys;
}



-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    
    [super restoreDataFromDict:restoreDict];

    self.delay = [restoreDict[@"delay"] floatValue];
    if (self.downMixer && restoreDict[@"downMixerData"])
    {
        [self.downMixer restoreData:restoreDict[@"downMixerData"]];
    }
    
    if ([restoreDict objectForKey:@"isGlobal"])
    {
        self.isGlobal = [restoreDict[@"isGlobal"] boolValue];
    }
    
    NSArray *outputTracks = restoreDict[@"outputTracksUUIDs"];
    if (outputTracks)
    {
        for(NSString *trackUUID in outputTracks)
        {
            CAMultiAudioOutputTrack *track = self.engine.outputTracks[trackUUID];
            [self.engine addInput:self toTrack:track];
        }
    }
}



-(void)setDelay:(Float32)delay
{
    if (self.delayNodes)
    {
        Float32 nodeDelay = delay;
        for (CAMultiAudioDelay *dNode in self.delayNodes)
        {
            if (nodeDelay >= 2.0)
            {
                dNode.delay = 2.0;
                nodeDelay -= 2.0;
                dNode.bypass = NO;
            } else {
                
                dNode.delay = nodeDelay;
                if (nodeDelay <= 0.0)
                {
                    dNode.bypass = YES;
                }
                nodeDelay -= nodeDelay;
            }
        }
    }
    
    _delay = delay;
}

-(Float32)delay
{
    return _delay;
}

-(void)setEnabled:(bool)enabled
{
    [super setEnabled:enabled];
    
    
    NSColor *newColor;
    if (enabled)
    {
        newColor = [NSColor greenColor];
    } else {
        newColor = [NSColor blackColor];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nameColor = newColor;
    });
}

-(void)openMixerWindow:(id)sender
{
    if (self.downMixer)
    {
        self.mixerWindow = [[CAMultiAudioMatrixMixerWindowController alloc] initWithAudioMixer:self];
        [self.mixerWindow showWindow:nil];
        self.mixerWindow.window.title = self.name;
    }
}

-(void)setVolume:(float)volume
{
    [super setVolume:volume];
    if (self.downMixer)
    {
        self.downMixer.volume = volume;
        
    }
}

-(void)didRemoveInput
{
    return;
}

-(void)removeFromEngine
{
    if (self.engine)
    {
        [self.engine removeInputAny:self];
    }
}


@end
