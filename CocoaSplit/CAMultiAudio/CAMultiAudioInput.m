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

-(void)addToOutputTrack:(NSString *)trackName
{
    [self willChangeValueForKey:@"outputTracks"];
    [self.engine addInput:self toTrack:trackName];
    [self didChangeValueForKey:@"outputTracks"];
    [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackInputAdded forObject:self];
}


-(void)removeFromOutputTrack:(NSString *)trackName
{
    [self willChangeValueForKey:@"outputTracks"];
    [self.engine removeInput:self fromTrack:trackName];
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
    

    if (self.converterNode)
    {
        if (![self.graph addNode:self.converterNode])
        {
            [self teardownGraph];
            return NO;
        }
        

    }
    

    self.downMixer = [[CAMultiAudioDownmixer alloc] initWithInputChannels:self.channelCount];
    
    if (![self.graph addNode:self.downMixer])
    {
        
        [self teardownGraph];
        return NO;
    }

    CAMultiAudioNode *connectTo = self.converterNode;
    if (!connectTo)
    {
        connectTo = self.downMixer;
    }
    
    

    if(![self.graph connectNode:self toNode:connectTo])
    {
        [self teardownGraph];
        return NO;
    }
    if (self.converterNode)
    {
        if(![self.graph connectNode:self.converterNode toNode:self.downMixer])
        {
            [self teardownGraph];
            return NO;
        }
    }
    
    CAMultiAudioDelay *delayNode;
    CAMultiAudioNode *connectNode = self.downMixer;
    
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
        ret = [self.graph connectNode:connectNode toNode:delayNode];
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
    
    

    self.effectsHead = delayNode;
    
    return YES;
    
}


-(void)setupEffectsChain
{
    [self setupGraph];
    [super setupEffectsChain];
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
    saveDict[@"outputTracks"] = self.outputTracks;
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
    
    NSDictionary *outputTracks = restoreDict[@"outputTracks"];
    if (outputTracks)
    {
        for(NSString *trackName in outputTracks)
        {
            [self.engine addInput:self toTrack:trackName];
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
