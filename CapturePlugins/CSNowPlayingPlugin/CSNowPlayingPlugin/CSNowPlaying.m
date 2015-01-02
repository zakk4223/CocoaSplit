//
//  CSNowPlaying.m
//  CSNowPlayingPlugin
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSNowPlaying.h"

@implementation CSNowPlaying

-(instancetype)init
{
    if (self = [super init])
    {
        self.userFormatString = @"$artist - $songname  ";
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(spotifyChangedTrack:) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(iTunesChangedTrack:) name:@"com.apple.iTunes.playerInfo" object:nil];
        
    }
    
    return self;
}


-(void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    
}


-(void)iTunesChangedTrack:(NSNotification *)notify
{
    NSDictionary *trackInfo = notify.userInfo;
    self.text = [self formatUserStringWithDictionary:@{@"artist": trackInfo[@"Artist"], @"album": trackInfo[@"Album"], @"songname": trackInfo[@"Name"], @"tracknumber": trackInfo[@"Track Number"]}];
}



-(void)spotifyChangedTrack:(NSNotification *)notify
{
    
    NSDictionary *trackInfo = notify.userInfo;
    
    self.text = [self formatUserStringWithDictionary:@{@"artist": trackInfo[@"Artist"], @"album": trackInfo[@"Album"], @"songname": trackInfo[@"Name"], @"tracknumber": trackInfo[@"Track Number"]}];
    
    
    
}



-(NSString *)formatUserStringWithDictionary:(NSDictionary *)dataDict
{
    //$artist
    //$album
    //$songname
    //$tracknumber
    
    
    NSString *tmp;
    tmp = [self.userFormatString stringByReplacingOccurrencesOfString:@"$artist" withString:dataDict[@"artist"]];
    tmp = [tmp stringByReplacingOccurrencesOfString:@"$album" withString:dataDict[@"album"]];
    tmp = [tmp stringByReplacingOccurrencesOfString:@"$songname" withString:dataDict[@"songname"]];
    tmp = [tmp stringByReplacingOccurrencesOfString:@"$tracknumber" withString:dataDict[@"tracknumber"]];
    return tmp;
}


+(NSString *)label
{
    return @"Now Playing";
}


@end
