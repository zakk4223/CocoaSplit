//
//  CAMultiAudioInput.m
//  CocoaSplit
//
//  Created by Zakk on 7/30/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioInput.h"
#import "CAMultiAudioDelay.h"
#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioEqualizer.h"

@implementation CAMultiAudioInput
@synthesize delay = _delay;
@synthesize compressorBypass = _compressorBypass;


-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType
{
    if (self = [super initWithSubType:subType unitType:unitType])
    {
        _delayNodes = [NSMutableArray array];
        self.nameColor = [NSColor blackColor];
        _compressorBypass = YES;

    }
    
    return self;
}

-(void)setCompressorBypass:(bool)compressorBypass
{

    _compressorBypass = compressorBypass;
    
    if (self.dynamicCompressor)
    {
        self.dynamicCompressor.bypass = compressorBypass;
    }
}

-(bool) compressorBypass
{
    return _compressorBypass;
}



-(bool)teardownGraph
{
    if (!self.graph)
    {
        //!?!?!
        return NO;
    }
    
    [self.graph removeNode:self];
    
    if (self.converterNode)
    {
        [self.graph removeNode:self.converterNode];
    }
    
    if (self.downMixer)
    {
        [self.graph removeNode:self.downMixer];
    }
    
    NSArray *delayNodes = self.delayNodes.copy;
    for (CAMultiAudioDelay *dNode in [delayNodes reverseObjectEnumerator])
    {
        [self.graph removeNode:dNode];
        [self.delayNodes removeObject:dNode];
    }
    
    if (self.equalizer)
    {
        [self.graph removeNode:self.equalizer];
    }
    
    self.converterNode = nil;
    self.downMixer = nil;
    self.equalizer = nil;
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
    
    self.equalizer = [[CAMultiAudioEqualizer alloc] init];
    if (![self.graph addNode:self.equalizer])
    {
        
        [self teardownGraph];
        return NO;
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
        [self.delayNodes addObject:delayNode];
    }
    
    if(![self.graph connectNode:delayNode toNode:self.equalizer])
    {
        [self teardownGraph];
        return NO;
    }
    

    
    
    self.headNode = self.equalizer;
    
    return YES;
    
}



-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    [super saveDataToDict:saveDict];
    saveDict[@"delay"] = [NSNumber numberWithFloat:self.delay];
    saveDict[@"compressorBypass"] = [NSNumber numberWithBool:self.compressorBypass];
    if (self.downMixer)
    {
        saveDict[@"downMixerData"] = [self.downMixer saveData];
    }
    
    if (self.equalizer)
    {
        saveDict[@"equalizerData"] = [self.equalizer saveData];

    }
    
    if (self.dynamicCompressor)
    {
        saveDict[@"compressorData"] = [self.dynamicCompressor saveData];
    }
}

-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    
    [super restoreDataFromDict:restoreDict];
    if (restoreDict[@"compressorBypass"])
    {
        self.compressorBypass = [restoreDict[@"compressorBypass"] boolValue];
    }
    
    self.delay = [restoreDict[@"delay"] floatValue];
    if (self.downMixer && restoreDict[@"downMixerData"])
    {
        [self.downMixer restoreData:restoreDict[@"downMixerData"]];
    }
    if (self.equalizer && restoreDict[@"equalizerData"])
    {
        [self.equalizer restoreData:restoreDict[@"equalizerData"]];
    }
    
    if (self.dynamicCompressor)
    {
        self.dynamicCompressor.bypass = self.compressorBypass;
        
        if (restoreDict[@"compressorData"])
        {
            [self.dynamicCompressor restoreData:restoreDict[@"compressorData"]];
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
            } else {
                dNode.delay = nodeDelay;
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




@end
