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



-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType
{
    if (self = [super initWithSubType:subType unitType:unitType])
    {
        _delayNodes = [NSMutableArray array];
        self.nameColor = [NSColor blackColor];

    }
    
    return self;
}

-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    [super saveDataToDict:saveDict];
    saveDict[@"delay"] = [NSNumber numberWithFloat:self.delay];
    if (self.downMixer)
    {
        saveDict[@"downMixerData"] = [self.downMixer saveData];
    }
    
    if (self.equalizer)
    {
        saveDict[@"equalizerData"] = [self.equalizer saveData];

    }
}

-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    
    [super restoreDataFromDict:restoreDict];
    self.delay = [restoreDict[@"delay"] floatValue];
    if (self.downMixer && restoreDict[@"downMixerData"])
    {
        [self.downMixer restoreData:restoreDict[@"downMixerData"]];
    }
    if (self.equalizer && restoreDict[@"equalizerData"])
    {
        [self.equalizer restoreData:restoreDict[@"equalizerData"]];
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
