//
//  TwitchStreamService.m
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "TwitchStreamService.h"
#import "TwitchStreamServiceViewController.h"


@implementation TwitchStreamService

-(instancetype) init
{
    if(self = [super init])
    {
        self.isReady = YES;
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.selectedServer forKey:@"selectedServer"];
    [aCoder encodeObject:self.streamKey forKey:@"streamKey"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.selectedServer = [aDecoder decodeObjectForKey:@"selectedServer"];
        self.streamKey = [aDecoder decodeObjectForKey:@"streamKey"];
    }
    return self;
}


-(NSViewController *)getConfigurationView
{
    
    TwitchStreamServiceViewController *configViewController;
    [self loadTwitchIngest];
    
    configViewController = [[TwitchStreamServiceViewController alloc] initWithNibName:@"TwitchStreamServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}



-(NSString *)getServiceFormat
{
    return @"FLV";
}


-(NSString *)getServiceDestination
{
    
    
    
    if (self.selectedServer)
    {
        NSString *destination = [self.selectedServer stringByReplacingOccurrencesOfString:@"{stream_key}" withString:self.streamKey];
        return destination;
    }
    
    return nil;
}



+(NSString *)label
{
    return @"TwitchTV";
}


+(NSString *)serviceDescription
{
    return @"TwitchTV";
}


-(void)fetchTwitchStreamKey
{
    if (!self.oAuthKey)
    {
        return;
    }
    
    NSString *apiString = @"https://api.twitch.tv/kraken/channel";
    
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    [apiRequest setValue:[NSString stringWithFormat:@"OAuth %@", self.oAuthKey] forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:apiRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        
        NSError *jsonError;
        NSDictionary *channel_response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        //Handle error
        
        
        NSString *stream_key = [channel_response objectForKey:@"stream_key"];
        
        dispatch_async(dispatch_get_main_queue(), ^{self.streamKey = stream_key; });
        return;
    }];
}


-(void)loadTwitchIngest
{
    
    NSString *apiString = @"https://api.twitch.tv/kraken/ingests";
    
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    [NSURLConnection sendAsynchronousRequest:apiRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        
        NSError *jsonError;
        NSDictionary *ingest_response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        //Handle error
        
        NSArray *ingest_list = [ingest_response objectForKey:@"ingests"];
        
        NSMutableArray *cooked_ingests = [[NSMutableArray alloc] init];
        
        for (NSDictionary *tw_ingest in ingest_list)
        {
            
            NSMutableDictionary *ingest_map = [[NSMutableDictionary alloc] init];
            
            NSString *url_temp = [tw_ingest objectForKey:@"url_template"];
            NSString *name = [tw_ingest objectForKey:@"name"];
            
            
            
            if (!url_temp || !name)
            {
                continue;
            }
            
            [ingest_map setValue: url_temp forKey:@"destination"];
            [ingest_map setValue:name forKey:@"name"];
            [cooked_ingests addObject:ingest_map];
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{self.twitchServers = cooked_ingests; });
        
        
        
        return;
    }];
}



@end
