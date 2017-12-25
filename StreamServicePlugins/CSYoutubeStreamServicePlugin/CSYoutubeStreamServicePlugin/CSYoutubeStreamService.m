//
//  CSYoutubeStreamService.m
//  CSYoutubeStreamServicePlugin
//
//  Created by Zakk on 7/24/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSYoutubeStreamService.h"
#import "CSYoutubeStreamServiceViewController.h"

@implementation CSYoutubeStreamService

@synthesize accountName = _accountName;


-(instancetype) init
{
    if(self = [super init])
    {
        self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"youtube"];
        if (self.knownAccounts.count == 1)
        {
            self.accountName = self.knownAccounts.firstObject;
        }
    }
    
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accountName forKey:@"accountName"];
    if (self.selectedLiveStream)
    {
        NSString *streamID = self.selectedLiveStream[@"id"];
        [aCoder encodeObject:streamID forKey:@"selectedStreamID"];
    }
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.accountName = [aDecoder decodeObjectForKey:@"accountName"];
        _saved_selected_streamID = [aDecoder decodeObjectForKey:@"selectedStreamID"];
        
        if (self.accountName)
        {
            [self fetchliveStreams];
        }
    }
    return self;
}



-(NSString *)accountName
{
    return _accountName;
}

-(void)setAccountName:(NSString *)accountName
{
    _accountName = accountName;
    self.oauthObject = nil;
    [self fetchliveStreams];
}


+(NSString *)label
{
    return @"Youtube";
}


+(NSString *)serviceDescription
{
    return @"Youtube";
}

+(NSImage *)serviceImage
{
    
    
    return [[NSBundle bundleForClass:[self class]] imageForResource:@"YouTube-icon-full_color"];
}




-(void)prepareForStreamStart
{
    if (!_destination_fetch_pending)
    {
        @synchronized (self) {
            _currentStreamDest = nil;
            _destination_fetch_pending = YES;
        }
        
        [self fetchStreamDestination];
        
    }
}

-(NSString *)getServiceDestination
{
    return _currentStreamDest;
}

-(void)fetchStreamDestination
{
    if (!self.selectedLiveStream)
    {
        return;
    }
    
    [self createAuthenticator];
    
    if (!self.oauthObject)
    {
        return;
    }

    
    NSString *boundStreamID = self.selectedLiveStream[@"contentDetails"][@"boundStreamId"];
    
    if (!boundStreamID)
    {
        return;
    }
    
    NSString *apiString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/liveStreams?part=cdn&id=%@&fields=items", boundStreamID];
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
        
        NSDictionary *streamResponse = (NSDictionary *)decodedData;
        NSArray *items = streamResponse[@"items"];
        if (!items || items.count < 1)
        {
            return;
        }
        
        NSDictionary *streamObj = items.firstObject;
        
        NSDictionary *cdnMap = streamObj[@"cdn"];
        
        if (!cdnMap)
        {
            return;
        }
        
        NSDictionary *ingestion = cdnMap[@"ingestionInfo"];
        
        NSString *streamKey = ingestion[@"streamName"];
        NSString *streamAddress = ingestion[@"ingestionAddress"];
        
        
        if (streamKey && streamAddress)
        {
            _currentStreamDest = [NSString stringWithFormat:@"%@/%@", streamAddress, streamKey];
            _destination_fetch_pending = NO;
        }
        
        
        //dispatch_async(dispatch_get_main_queue(), ^{self.streamKey = stream_key; _key_fetch_pending = NO;});
    }];
    
}

-(NSString *)getServiceFormat
{
    return @"FLV";
}

-(void)selectStream
{
    NSString *useID = _saved_selected_streamID;
    NSDictionary *selectedStream = nil;
    
    _saved_selected_streamID = nil;
    
    if (self.selectedLiveStream)
    {
        useID = self.selectedLiveStream[@"id"];
    }
    
    for(NSDictionary *stream in self.liveStreams)
    {
        if (useID)
        {
            if ([stream[@"id"] isEqualToString:useID])
            {
                selectedStream = stream;
                break;
            }
        }
        
        NSNumber *defaultBroadcast = stream[@"snippet"][@"isDefaultBroadcast"];
        
        if (defaultBroadcast.boolValue)
        {
            selectedStream = stream;
        }
    }
    
    self.selectedLiveStream = selectedStream;
}


-(void)fetchliveStreams
{
    [self createAuthenticator];

    if (!self.oauthObject)
    {
        return;
    }
    
    NSString *apiString = @"https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id%2Csnippet%2CcontentDetails%2Cstatus&broadcastStatus=upcoming&broadcastType=all&fields=items(contentDetails%2FboundStreamId%2Cid%2Csnippet(description%2CisDefaultBroadcast%2Ctitle)%2Cstatus%2FlifeCycleStatus)";
    
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    
    
    
    [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
        
        NSDictionary *livestream_response = (NSDictionary *)decodedData;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.liveStreams = livestream_response[@"items"];
            [self selectStream];
        });
        
        //dispatch_async(dispatch_get_main_queue(), ^{self.streamKey = stream_key; _key_fetch_pending = NO;});
    }];
}


-(void)fetchAccountname:(CSOauth2Authenticator *)authenticator
{
    if (self.accountName)
    {
        [authenticator saveToKeychain:self.accountName];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"twitch"];
            [self fetchliveStreams];
        });

        return;
    }
    
    if (self.oauthObject && self.oauthObject.accessToken)
    {
        NSString *apiString = @"https://www.googleapis.com/oauth2/v2/userinfo";
        
        NSURL *apiURL = [NSURL URLWithString:apiString];
        
        
        
        NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
        
        [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
            
            NSDictionary *user_response = (NSDictionary *)decodedData;
            NSString *account_name = [user_response objectForKey:@"email"];
            [authenticator saveToKeychain:account_name];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.accountName = account_name;
                self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"twitch"];
                //[self fetchliveStreams];
            });
        }];
    }
}


-(void)authenticateUser
{
    [self createAuthenticator];
    
    self.oauthObject.forceVerify = YES;
    
    [self fetchliveStreams];
    
    self.oauthObject.forceVerify = NO;

    
    
}
     
     
-(void)createAuthenticator
{
    if (!self.oauthObject)
    {
        
        if (!_oauth_client_id)
        {
            _oauth_client_id = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"YoutubeClientID"];
        }
        
        if (!_oauth_client_secret)
        {
            _oauth_client_secret = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"YoutubeClientSecret"];
        }

        
        
        
        
        NSDictionary *oconfig = @{kCSOauth2ConfigAuthURL:@"https://accounts.google.com/o/oauth2/v2/auth", kCSOauth2ConfigRedirectURL:@"https://localhost:5555/", kCSOauth2ConfigScopes:@[@"profile", @"https://www.googleapis.com/auth/youtube.readonly", @"https://www.googleapis.com/auth/userinfo.email"], kCSOauth2AccessTokenRequestURL: @"https://www.googleapis.com/oauth2/v4/token", kCSOauth2AccessRefreshURL: @"https://www.googleapis.com/oauth2/v4/token", kCSOauth2ClientSecret: _oauth_client_secret};
        
        self.oauthObject = [[CSPluginServices sharedPluginServices] createOAuth2Authenticator:@"youtube" clientID:_oauth_client_id flowType:kCSOauth2CodeFlow config:oconfig];
        
        
        self.oauthObject.accountName = self.accountName;
        __weak CSYoutubeStreamService *weakSelf = self;
        self.oauthObject.accountNameFetcher = ^void(CSOauth2Authenticator *authenticator) {
            CSYoutubeStreamService *strongSelf = weakSelf;
            [strongSelf fetchAccountname:authenticator];
        };
    }
}


-(NSViewController *)getConfigurationView
{
    
    CSYoutubeStreamServiceViewController *configViewController;
    
    
    configViewController = [[CSYoutubeStreamServiceViewController alloc] initWithNibName:@"CSYoutubeStreamServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    
    configViewController.serviceObj = self;
    return configViewController;
}

@end
