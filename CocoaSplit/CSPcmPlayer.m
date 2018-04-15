//
//  CSPcmPlayer.m
//  CocoaSplit
//
//  Created by Zakk on 1/23/18.
//

#import <Foundation/Foundation.h>
#import "CsPcmPlayer.h"
#import "CAMultiAudioPCMPlayer.h"
#import "CAMultiAudioEngine.h"

@interface CSPcmPlayer ()
{
    NSMapTable *_realPlayers;
    AudioStreamBasicDescription *_asbd;
    
    //NSPointerArray *_realPlayers;
}

-(void) addPlayer:(id)player forUUID:(NSString *)uuid;
-(void)removePlayerForUUID:(NSString *)uuid;


@end

@implementation CSPcmPlayer
@synthesize name = _name;


-(void)setAudioFormat:(AudioStreamBasicDescription *)asbd
{
    if (!asbd)
    {
        if (_asbd)
        {
            free(_asbd);
        }
        _asbd = NULL;
    } else {
        if (!_asbd)
        {
            _asbd = malloc(sizeof(AudioStreamBasicDescription));
        }
        memcpy(_asbd, asbd, sizeof(AudioStreamBasicDescription));
    }
    

    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        CAMultiAudioEngine *useEngine = player.engine;
        [player removeFromEngine];
        player.inputFormat = asbd;
        [useEngine attachInput:player];
    }];
    
}


-(void)setName:(NSString *)name
{
    
    _name = name;
    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        player.name = name;
    }];
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
        @synchronized(player)
        {
            [player removeFromEngine];
        }
    }
    @synchronized(self)
    {
        [_realPlayers removeObjectForKey:uuid];
    }
}


-(void) addPlayer:(id)player forUUID:(NSString *)uuid
{
    if (!_asbd)
    {
        CAMultiAudioPCMPlayer *caPlayer = player;
        _asbd = malloc(sizeof(AudioStreamBasicDescription));
        memcpy(_asbd, caPlayer.inputFormat, sizeof(AudioStreamBasicDescription));
    }
    
    
    @synchronized(self)
    {
        [_realPlayers setObject:player forKey:uuid];
    }
}

-(AudioStreamBasicDescription *)audioDescription
{
    return _asbd;

}




-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer
{

    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        [player scheduleBuffer:sampleBuffer];
    }];
}

-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer
{
    
    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        [player playPcmBuffer:pcmBuffer];
    }];
    return YES;
}


-(void)play
{
    
    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        [player play];
    }];
}

-(void)pause
{
    
    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        [player pause];
    }];
}

-(void)flush
{
    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        [player flush];
    }];
}

-(void)dealloc
{

    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        [player removeFromEngine];
    }];
    if (_asbd)
    {
        free(_asbd);
    }
}

-(void)runBlockForPlayers:(void (^)(CAMultiAudioPCMPlayer *player))useBlock
{
    @synchronized(self)
    {
        for (NSString *uuid in _realPlayers)
        {
            CAMultiAudioPCMPlayer *player = [_realPlayers objectForKey:uuid];
            if (player)
            {
                useBlock(player);
            }
        }
    }
}
@end
