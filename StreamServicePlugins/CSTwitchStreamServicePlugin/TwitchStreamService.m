//
//  TwitchStreamService.m
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//

#import "TwitchStreamService.h"
#import "TwitchStreamServiceViewController.h"


@implementation TwitchStreamService

@synthesize accountName = _accountName;

-(instancetype) init
{
    if(self = [super init])
    {
        self.isReady = YES;
        self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"twitch"];
    }
    
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.selectedServer forKey:@"selectedServer"];
    [aCoder encodeObject:self.streamKey forKey:@"streamKey"];
    [aCoder encodeObject:self.accountName forKey:@"accountName"];
    [aCoder encodeBool:self.alwaysFetchKey forKey:@"alwaysFetchKey"];
    [aCoder encodeBool:self.bandwidthTest forKey:@"bandwidthTest"];
    
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.selectedServer = [aDecoder decodeObjectForKey:@"selectedServer"];
        self.streamKey = [aDecoder decodeObjectForKey:@"streamKey"];
        self.accountName = [aDecoder decodeObjectForKey:@"accountName"];
        self.alwaysFetchKey = [aDecoder decodeBoolForKey:@"alwaysFetchKey"];
        self.bandwidthTest = [aDecoder decodeBoolForKey:@"bandwidthTest"];
        
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


-(NSString *)accountName
{
    return _accountName;
}

-(void)setAccountName:(NSString *)accountName
{
    _accountName = accountName;
    self.oauthObject = nil;
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
        NSString *destination;
        
        NSString *baseDestination = [self.selectedServer stringByReplacingOccurrencesOfString:@"{stream_key}" withString:self.streamKey];
        if (self.bandwidthTest)
        {
            destination = [NSString stringWithFormat:@"%@?bandwidthtest=true", baseDestination];
        } else {
            destination = baseDestination;
        }
        
        return destination;
    }
    
    return nil;
}



+(NSString *)label
{
    return @"Twitch";
}


+(NSString *)serviceDescription
{
    return @"Twitch";
}


+(NSImage *)serviceImage
{
    NSImage *ret = [[NSBundle bundleForClass:[self class]] imageForResource:@"GlitchIcon_PurpleonWhite"];
    
    return ret;
}




-(void)createAuthenticator
{
    if (!self.oauthObject)
    {
        
        if (!_oauth_client_id)
        {
            _oauth_client_id = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"TwitchAPIClientID"];
        }
        
        NSDictionary *oconfig = @{kCSOauth2ConfigAuthURL:@"https://api.twitch.tv/kraken/oauth2/authorize", kCSOauth2ConfigRedirectURL:@"cocoasplit-twitch://cocoasplit.com/oauth/redirect", kCSOauth2ConfigScopes:@[@"channel_read", @"user_read"], kCSOauth2ExtraAuthHeaders:@{@"Accept": @"application/vnd.twitchtv.v5+json"}};
        
        self.oauthObject = [[CSPluginServices sharedPluginServices] createOAuth2Authenticator:@"twitch" clientID:_oauth_client_id flowType:kCSOauth2ImplicitGrantFlow config:oconfig];
        
        
        self.oauthObject.accountName = self.accountName;
        __weak TwitchStreamService *weakSelf = self;
        
        self.oauthObject.accountNameFetcher = ^void(CSOauth2Authenticator *authenticator) {
            TwitchStreamService *strongSelf = weakSelf;
            [strongSelf fetchAccountname:authenticator];
        };
    }
}

-(void)authenticateUser
{
    self.accountName = nil;
    
    [self createAuthenticator];
    self.oauthObject.forceVerify = YES;
    [self.oauthObject configurationVariableSet:@{@"force_verify": @"true"} forName:kCSOauth2ExtraAuthParams];
    
    [self fetchTwitchStreamKey];
    self.oauthObject.forceVerify = NO;
    [self.oauthObject configurationVariableRemove:kCSOauth2ExtraAuthParams];
    
}




-(void)fetchAccountname:(CSOauth2Authenticator *)authenticator
{
    if (self.accountName)
    {
        [authenticator saveToKeychain:self.accountName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"twitch"];
        });


        return;
    }
    
    if (self.oauthObject && self.oauthObject.accessToken)
    {
        NSString *apiString = @"https://api.twitch.tv/kraken/channel";
        
        NSURL *apiURL = [NSURL URLWithString:apiString];
        
        
        
        NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
        [apiRequest setValue:@"application/vnd.twitchtv.v5+json" forHTTPHeaderField:@"Accept"];

        [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
            
            NSDictionary *user_response = (NSDictionary *)decodedData;
            NSString *account_name = [user_response objectForKey:@"name"];
            [authenticator saveToKeychain:account_name];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.accountName = account_name;
                self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"twitch"];
            });
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
    [apiRequest setValue:@"application/vnd.twitchtv.v5+json" forHTTPHeaderField:@"Accept"];

    [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
        
        NSDictionary *channel_response = (NSDictionary *)decodedData;
        NSString *stream_key = [channel_response objectForKey:@"stream_key"];
        dispatch_async(dispatch_get_main_queue(), ^{self.streamKey = stream_key; self->_key_fetch_pending = NO;});
    }];
}


-(void)loadTwitchIngest
{
    
    NSString *apiString = @"https://api.twitch.tv/kraken/ingests";
    
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    if (!_oauth_client_id)
    {
        _oauth_client_id = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"TwitchAPIClientID"];
    }

    [apiRequest setValue:@"application/vnd.twitchtv.v5+json" forHTTPHeaderField:@"Accept"];
    
    [apiRequest setValue:_oauth_client_id forHTTPHeaderField:@"Client-ID"];
    [NSURLConnection sendAsynchronousRequest:apiRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        
        if (err)
        {
            return;
        }
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
