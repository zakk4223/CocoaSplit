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


-(instancetype)initWithAudioNode:(AVAudioNode *)audioNode
{
    if (self = [super initWithAudioNode:audioNode])
    {

        [self commonInit];
    }
    
    return self;
}


-(instancetype)init
{
    if (self = [super init])
    {
        [self commonInit];

    }
    return self;
}


-(void)commonInit
{
    self.isGlobal = NO;
    _delayNodes = [NSMutableArray array];
    self.powerLevels = [NSMutableDictionary dictionary];
    [self.powerLevels setObject:[NSMutableArray array] forKey:@"input"];
    [self.powerLevels setObject:[NSMutableArray array] forKey:@"output"];
    self.outputTracks = [NSMutableDictionary dictionary];
}
/*
-(void)updatePowerlevel
{
    if (!self.downMixer)
    {
        return;
    }
    
    return;
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

 */
-(void)addToOutputTrack:(CAMultiAudioOutputTrack *)outputTrack
{
    [self willChangeValueForKey:@"outputTracks"];
    [self.engine addInput:self toTrack:outputTrack];
    [self didChangeValueForKey:@"outputTracks"];
    [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackInputAdded forObject:self];
}


-(void)removeFromOutputTrack:(CAMultiAudioOutputTrack *)outputTrack
{
    [self willChangeValueForKey:@"outputTracks"];
    [self.engine removeInput:self fromTrack:outputTrack];
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
    

    self.downMixer = nil;
    self.headNode = self;
    return YES;
}


-(bool)setupGraph
{
    
    //self.downMixer = [[CAMultiAudioMixer alloc] init];
    AVAudioFormat *useFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:self.inputFormat.sampleRate channels:self.inputFormat.channelCount];
    /*if (![self.graph addNode:self.downMixer])
    {
        
        [self teardownGraph];
        return NO;
    }*/



    CAMultiAudioDelay *delayNode;
    CAMultiAudioNode *connectNode = self;
    
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
        ret = [self.graph connectNode:connectNode toNode:delayNode withFormat:useFormat];
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
    NSLog(@"HEAD NODE %@", self.headNode);
    return YES;
    
}

-(void)setupDownmixer
{
    AVAudioFormat *useFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:self.inputFormat.sampleRate channels:self.inputFormat.channelCount];

    self.downMixer = [[CAMultiAudioMixer alloc] init];
    [self.graph addNode:self.downMixer];
    [self.graph connectNode:self.headNode toNode:self.downMixer withFormat:useFormat];
    self.headNode = self.downMixer;
    self.downMixer.volume = 1.0f;
}

-(void)setupEffectsChain
{
    [self setupGraph];
   // [super setupEffectsChain];
    [self setupDownmixer];
    
}

-(void)removeEffectsChain
{
    [self teardownGraph];
    [super removeEffectsChain];
}


-(AVAudioFormat *)inputFormat
{
    return self.graph.graphFormat;
}

-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    [super saveDataToDict:saveDict];
    saveDict[@"delay"] = [NSNumber numberWithFloat:self.delay];
    if (self.downMixer)
    {
        //saveDict[@"downMixerData"] = [self.downMixer saveData];
    }
    saveDict[@"isGlobal"] = [NSNumber numberWithBool:self.isGlobal];
    saveDict[@"outputTracks"] = self.outputTracks.copy;
}



-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    
    [super restoreDataFromDict:restoreDict];

    self.delay = [restoreDict[@"delay"] floatValue];
    if (self.downMixer && restoreDict[@"downMixerData"])
    {
        //[self.downMixer restoreData:restoreDict[@"downMixerData"]];
    }
    
    if ([restoreDict objectForKey:@"isGlobal"])
    {
        self.isGlobal = [restoreDict[@"isGlobal"] boolValue];
    }
    
    NSDictionary *outputTracks = restoreDict[@"outputTracks"];
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
