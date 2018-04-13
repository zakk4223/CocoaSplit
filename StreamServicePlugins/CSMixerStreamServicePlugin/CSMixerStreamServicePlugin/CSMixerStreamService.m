//
//  CSMixerStreamService.m
//  CSMixerStreamServicePlugin
//
//  Created by Zakk on 4/13/18.
//

#import "CSMixerStreamService.h"
#import "CSMixerStreamServiceViewController.h"


@implementation CSMixerStreamService
@synthesize accountName = _accountName;


-(instancetype) init
{
    if (self = [super init])
    {
        self.isReady = YES;
        self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"mixer"];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.selectedIngest forKey:@"selectedIngest"];
    [aCoder encodeObject:self.streamKey forKey:@"streamKey"];
    [aCoder encodeObject:self.accountName forKey:@"accountName"];
    [aCoder encodeBool:self.alwaysFetchKey forKey:@"alwaysFetchKey"];
    [aCoder encodeObject:_channel_id forKey:@"channelID"];
    
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.selectedIngest = [aDecoder decodeObjectForKey:@"selectedIngest"];
        self.streamKey = [aDecoder decodeObjectForKey:@"streamKey"];
        self.accountName = [aDecoder decodeObjectForKey:@"accountName"];
        self.alwaysFetchKey = [aDecoder decodeBoolForKey:@"alwaysFetchKey"];
        _channel_id = [aDecoder decodeObjectForKey:@"channelID"];
    }
    return self;
}


+(NSImage *)serviceImage
{
    NSImage *ret = [[NSBundle bundleForClass:[self class]] imageForResource:@"MixerMerge_Light"];
    return ret;
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


+(NSString *)label
{
    return @"Mixer";
}

+(NSString *)serviceDescription
{
    return @"Mixer";
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
        
        [self fetchStreamKey];
        
    }
}

-(NSString *)getServiceDestination
{
    
    
    if (!self.streamKey)
    {
        return nil;
    }
    
    if (self.selectedIngest)
    {
        NSString *destHost = self.selectedIngest[@"host"];
        NSString *destination;
        if (destHost)
        {
            destination = [NSString stringWithFormat:@"rtmp://%@:1935/beam/%d-%@", destHost, _channel_id.unsignedIntegerValue, self.streamKey];
        }
        return destination;
    }
    
    return nil;
}


-(void)authenticateUser
{
    self.accountName = nil;
    
    [self createAuthenticator];
    self.oauthObject.forceVerify = YES;
    [self.oauthObject configurationVariableSet:@{@"force_verify": @"true"} forName:kCSOauth2ExtraAuthParams];
    
    [self fetchStreamKey];
    self.oauthObject.forceVerify = NO;
    [self.oauthObject configurationVariableRemove:kCSOauth2ExtraAuthParams];
    
}



-(void)fetchStreamKey
{
    
    if (!_channel_id)
    {
        [self createAuthenticator];
        
        NSString *apiString = @"https://mixer.com/api/v1/users/current";
        NSURL *apiURL = [NSURL URLWithString:apiString];
        NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
        [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
            
            NSDictionary *user_response = (NSDictionary *)decodedData;
            //NSString *username = [user_response objectForKey:username];
            //self.accountName = username;
            NSDictionary *channel = [user_response objectForKey:@"channel"];
            if (channel)
            {
                _channel_id = [channel objectForKey:@"id"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self fetchStreamKeyReal];
                });
            }
        }];
    } else {
        [self fetchStreamKeyReal];
    }
    
}
-(void)fetchStreamKeyReal
{
    [self createAuthenticator];
    if (!_channel_id)
    {
        return;
    }

    NSString *apiString = [NSString stringWithFormat:@"https://mixer.com/api/v1/channels/%d/details", _channel_id.unsignedIntValue];

    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    
    //[apiRequest setValue:[NSString stringWithFormat:@"OAuth %@", self.oAuthKey] forHTTPHeaderField:@"Authorization"];
    
    [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
        
        NSDictionary *channel_response = (NSDictionary *)decodedData;
        if (channel_response)
        {
            NSString *stream_key = [channel_response objectForKey:@"streamKey"];
            dispatch_async(dispatch_get_main_queue(), ^{self.streamKey = stream_key; /*_key_fetch_pending = NO;*/});
        }

    }];
}
    
-(void)createAuthenticator
{
    if (!self.oauthObject)
    {
        
        if (!_oauth_client_id)
        {
            _oauth_client_id = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"MixerAPIClientID"];
        }
        
        NSDictionary *oconfig = @{kCSOauth2ConfigAuthURL:@"https://mixer.com/oauth/authorize", kCSOauth2ConfigRedirectURL:@"https://mixeroauth.cocoasplit.com/oauth/redirect", kCSOauth2ConfigScopes:@[@"channel:streamKey:self", @"channel:details:self", @"user:details:self"]};
        
        self.oauthObject = [[CSPluginServices sharedPluginServices] createOAuth2Authenticator:@"mixer" clientID:_oauth_client_id flowType:kCSOauth2ImplicitGrantFlow config:oconfig];
        
        
        self.oauthObject.accountName = self.accountName;
        __weak CSMixerStreamService *weakSelf = self;
        
        self.oauthObject.accountNameFetcher = ^void(CSOauth2Authenticator *authenticator) {
            CSMixerStreamService *strongSelf = weakSelf;
            [strongSelf fetchAccountname:authenticator];
        };
    }
}

-(void)fetchAccountname:(CSOauth2Authenticator *)authenticator
{
    if (self.accountName)
    {
        [authenticator saveToKeychain:self.accountName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"mixer"];
        });
        
        
        return;
    }
    
    if (self.oauthObject && self.oauthObject.accessToken)
    {
        NSString *apiString = @"https://mixer.com/api/v1/users/current";
        
        NSURL *apiURL = [NSURL URLWithString:apiString];
        
        
        
        NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
        
        [self.oauthObject jsonRequest:apiRequest completionHandler:^(id decodedData) {
            
            NSDictionary *user_response = (NSDictionary *)decodedData;
            
            NSString *account_name = [user_response objectForKey:@"username"];
            NSDictionary *channel = [user_response objectForKey:@"channel"];
            if (channel)
            {
                _channel_id = [channel objectForKey:@"id"];
            }
            [authenticator saveToKeychain:account_name];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.accountName = account_name;
                self.knownAccounts = [[CSPluginServices sharedPluginServices] accountNamesForService:@"mixer"];
            });
        }];
    }
}

-(void)loadMixerIngests
{
    
    NSString *apiString = @"https://mixer.com/api/v1/ingests";
    
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];

    [NSURLConnection sendAsynchronousRequest:apiRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        
        if (err)
        {
            return;
        }
        NSError *jsonError;
        NSDictionary *ingest_response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        dispatch_async(dispatch_get_main_queue(), ^{self.ingests = ingest_response; });

        
        
        return;
    }];
}


-(NSViewController *)getConfigurationView
{
    
    CSMixerStreamServiceViewController *configViewController;
    [self loadMixerIngests];
    configViewController = [[CSMixerStreamServiceViewController alloc] initWithNibName:@"CSMixerStreamServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}


@end
