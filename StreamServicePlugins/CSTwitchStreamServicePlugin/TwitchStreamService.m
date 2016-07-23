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
    [aCoder encodeObject:self.accountName forKey:@"accountName"];
    [aCoder encodeBool:self.alwaysFetchKey forKey:@"alwaysFetchKey"];
    
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.selectedServer = [aDecoder decodeObjectForKey:@"selectedServer"];
        self.streamKey = [aDecoder decodeObjectForKey:@"streamKey"];
        self.accountName = [aDecoder decodeObjectForKey:@"accountName"];
        self.alwaysFetchKey = [aDecoder decodeBoolForKey:@"alwaysFetchKey"];
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


-(void)prepareForStreamStart
{
    if (self.alwaysFetchKey && !_key_fetch_pending)
    {
        @synchronized (self) {
            self.streamKey = nil;
            _key_fetch_pending = YES;
        }
        
        [self fetchTwitchStreamKey];
        
    }
}


-(NSString *)getServiceDestination
{
    

    if (!self.streamKey)
    {
        return nil;
    }
    
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



-(void)createAuthenticator
{
    if (!self.oauthObject)
    {
        
        if (!_oauth_client_id)
        {
            _oauth_client_id = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"TwitchAPIClientID"];
        }
        self.oauthObject = [[CSPluginServices sharedPluginServices] createOAuth2Authenticator:@"twitch" authLocation:@"https://api.twitch.tv/kraken/oauth2/authorize" clientID:_oauth_client_id redirectURL:@"cocoasplit-twitch://cocoasplit.com/oauth/redirect" authScopes:@[@"channel_read", @"user_read"] forceVerify:NO useKeychain:YES];
        self.oauthObject.accountName = self.accountName;
        self.oauthObject.accountNameFetcher = ^void(CSOauth2Authenticator *authenticator) {
            [self fetchAccountname:authenticator];
        };
    }
}

-(void)authenticateUser
{
    [self createAuthenticator];
    self.oauthObject.forceVerify = YES;
    self.oauthObject.extraAuthParams = @{@"force_verify": @"true"};
    [self fetchTwitchStreamKey];
    self.oauthObject.forceVerify = NO;
    self.oauthObject.extraAuthParams = nil;
}




-(void)fetchAccountname:(CSOauth2Authenticator *)authenticator
{
    if (self.accountName)
    {
        [authenticator saveToKeychain:self.accountName];
        return;
    }
    
    if (self.oauthObject && self.oauthObject.accessToken)
    {
        NSString *apiString = @"https://api.twitch.tv/kraken/channel";
        
        NSURL *apiURL = [NSURL URLWithString:apiString];
        
        
        
        NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
        
        [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
            
            NSDictionary *user_response = (NSDictionary *)decodedData;
            NSString *account_name = [user_response objectForKey:@"name"];
            [authenticator saveToKeychain:account_name];
            
            dispatch_async(dispatch_get_main_queue(), ^{self.accountName = account_name; });
        }];
    }
}



-(void)fetchTwitchStreamKey
{
    
    [self createAuthenticator];
    
    NSString *apiString = @"https://api.twitch.tv/kraken/channel";
    
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    
    //[apiRequest setValue:[NSString stringWithFormat:@"OAuth %@", self.oAuthKey] forHTTPHeaderField:@"Authorization"];
    
    [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
        
        NSDictionary *channel_response = (NSDictionary *)decodedData;
        NSString *stream_key = [channel_response objectForKey:@"stream_key"];
        
        dispatch_async(dispatch_get_main_queue(), ^{self.streamKey = stream_key; _key_fetch_pending = NO;});
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
