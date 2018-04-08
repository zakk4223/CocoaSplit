//
//  CSPcmPlayer.m
//  CocoaSplit
//
//  Created by Zakk on 1/23/18.
//

#import <Foundation/Foundation.h>
#import "CsPcmPlayer.h"
#import "CAMultiAudioPCMPlayer.h"

@interface CSPcmPlayer ()
{
    NSMapTable *_realPlayers;
    
    //NSPointerArray *_realPlayers;
}

-(void) addPlayer:(id)player forUUID:(NSString *)uuid;
-(void)removePlayerForUUID:(NSString *)uuid;


@end

@implementation CSPcmPlayer
@synthesize name = _name;


-(void)setName:(NSString *)name
{
    
    _name = name;
    for (NSString *uuid in _realPlayers)
    {
        CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
        if (player)
        {
            player.name = name;
        }
    }
}

-(NSString *)name
{
    return _name;
}


-(instancetype) init
{
    if (self = [super init])
    {
        _realPlayers = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

-(void)removePlayerForUUID:(NSString *)uuid
{
    CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
    if (player)
    {
        [player removeFromEngine];
    }
    [_realPlayers removeObjectForKey:uuid];
}


-(void) addPlayer:(id)player forUUID:(NSString *)uuid
{
    [_realPlayers setObject:player forKey:uuid];
    //[_realPlayers addPointer:(__bridge void * _Nullable)(player)];
}

-(AudioStreamBasicDescription *)audioDescription
{
    if (_realPlayers)
    {
        for (NSString *uuid in _realPlayers)
        {
            CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
            if (player)
            {
                return player.inputFormat;
            }
        }
    }
    
    return NULL;
}




-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer
{

    for (NSString *uuid in _realPlayers)
    {
        CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
        if (player)
        {
            [player scheduleBuffer:sampleBuffer];
        }
    }
}

-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer
{
    for (NSString *uuid in _realPlayers)
    {
        CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
        if (player)
        {
            [player playPcmBuffer:pcmBuffer];
        }
    }
    
    
    return YES;
}


-(void)play
{
    for (NSString *uuid in _realPlayers)
    {
        CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
        if (player)
        {
            [player play];
        }
    }
}

-(void)pause
{
    for (NSString *uuid in _realPlayers)
    {
        CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
        if (player)
        {
            [player pause];
        }
    }
}

-(void)flush
{
    for (NSString *uuid in _realPlayers)
    {
        CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
        if (player)
        {
            [player flush];
        }
    }
}

-(void)dealloc
{
    for (NSString *uuid in _realPlayers)
    {
        CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
        if (player)
        {
            [player removeFromEngine];
        }
    }
}


@end
