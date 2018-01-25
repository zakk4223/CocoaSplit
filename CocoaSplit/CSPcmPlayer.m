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
    NSPointerArray *_realPlayers;
}

-(instancetype) initWithPlayers:(NSArray  *)players;
-(void) addPlayer:(id)player;

@end

@implementation CSPcmPlayer
@synthesize name = _name;


-(void)setName:(NSString *)name
{
    
    _name = name;
    for (CAMultiAudioPCMPlayer *player in _realPlayers)
    {
        player.name = name;
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
        _realPlayers = [NSPointerArray weakObjectsPointerArray];
    }
    return self;
}

-(void) addPlayer:(id)player
{
    [_realPlayers addPointer:(__bridge void * _Nullable)(player)];
}

-(AudioStreamBasicDescription *)audioDescription
{
    if (_realPlayers)
    {
        for (CAMultiAudioPCMPlayer *player in _realPlayers)
        {
            return player.inputFormat;
        }
    }
    
    return NULL;
}


-(instancetype) initWithPlayers:(NSArray *)players
{
    if (self = [self init])
    {
        for (CAMultiAudioPCMPlayer *player in players)
        {
            [_realPlayers addPointer:(__bridge void * _Nullable)(player)];
        }
    }
    return self;
}


-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer
{

    for (CAMultiAudioPCMPlayer *player in _realPlayers)
    {
        if (player)
        {
            [player scheduleBuffer:sampleBuffer];
        }
    }
}

-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer
{
    for (CAMultiAudioPCMPlayer *player in _realPlayers)
    {
        if (player)
        {
            [player playPcmBuffer:pcmBuffer];
        }
    }
    
    
    return YES;
}


-(void)play
{
    for (CAMultiAudioPCMPlayer *player in _realPlayers)
    {
        if (player)
        {
            [player play];
        }
    }
}

-(void)pause
{
    for (CAMultiAudioPCMPlayer *player in _realPlayers)
    {
        if (player)
        {
            [player pause];
        }
    }
}

-(void)flush
{
    for (CAMultiAudioPCMPlayer *player in _realPlayers)
    {
        if (player)
        {
            [player flush];
        }
    }
}

-(void)dealloc
{
    for (CAMultiAudioPCMPlayer *player in _realPlayers)
    {
        if (player)
        {
            [player removeFromEngine];
        }
    }
}


@end
