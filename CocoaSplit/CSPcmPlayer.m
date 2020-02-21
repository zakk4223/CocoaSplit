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
    AVAudioFormat *_audioDescription;
    
    //NSPointerArray *_realPlayers;
}

-(void) addPlayer:(id)player forUUID:(NSString *)uuid;
-(void)removePlayerForUUID:(NSString *)uuid;


@end

@implementation CSPcmPlayer
@synthesize name = _name;


-(void)setAudioFormat:(AVAudioFormat *)avFmt
{

    _audioDescription = avFmt;
    [self runBlockForPlayers:^(CAMultiAudioPCMPlayer *player) {
        CAMultiAudioEngine *useEngine = player.engine;
        [player removeFromEngine];
        player.inputFormat = avFmt;
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
        @autoreleasepool
        {
            [_realPlayers removeObjectForKey:uuid];
        }
    }
}


-(void) addPlayer:(id)player forUUID:(NSString *)uuid
{
    
    if ([_realPlayers objectForKey:uuid])
    {
        return;
    }
    
    

    
    
    @synchronized(self)
    {
        [_realPlayers setObject:player forKey:uuid];
    }
}

-(AVAudioFormat *)audioDescription
{
    return _audioDescription;

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
}

-(void)runBlockForPlayers:(void (^)(CAMultiAudioPCMPlayer *player))useBlock
{
    @synchronized(self)
    {
        
        @autoreleasepool //We may not be in the main thread...
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
}
@end
