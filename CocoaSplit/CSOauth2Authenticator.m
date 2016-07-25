//
//  CSOauth2Authenticator.m
//  CocoaSplit
//
//  Created by Zakk on 7/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSOauth2Authenticator.h"

NSString *const kCSOauth2ConfigRedirectURL = @"CSOauth2ConfigRedirectURL";
NSString *const kCSOauth2ConfigScopes = @"CSOauth2ConfigScopes";
NSString *const kCSOauth2ConfigAuthURL = @"CSOauth2ConfigAuthURL";
NSString *const kCSOauth2CodeFlow = @"CSOauth2CodeFlow";
NSString *const kCSOauth2ImplicitGrantFlow = @"CSOauth2ImplicitGrantFlow";
NSString *const kCSOauth2ExtraAuthParams = @"CSOauth2ExtraAuthParams";
NSString *const kCSOauth2AccessTokenRequestURL = @"CSOauth2AccessTokenRequestURL";
NSString *const kCSOauth2AccessRefreshURL = @"CSOauth2AccessRefreshURL";
NSString *const kCSOauth2ClientSecret = @"CSOauth2ClientSecret";






@interface CSOauth2Authenticator()
{
    NSMutableDictionary *_config_dict;
}

@property (strong) NSString *refreshToken;
@property (strong) NSDate *expireDate;

@end


@implementation CSOauth2Authenticator

-(instancetype) initWithServiceName:(NSString *)serviceName clientID:(NSString *)client_id flowType:(NSString *)flow_type config:(NSDictionary *)config_dict
{
    if (self = [self init])
    {
        self.serviceName = serviceName;
        self.clientID = client_id;
        self.forceVerify = NO;
        self.useKeychain = YES;
        self.flowType = flow_type;

        if (config_dict)
        {
            _config_dict = [config_dict mutableCopy];
        } else {
            _config_dict = [[NSMutableDictionary alloc] init];
        }
    }
    
    return self;
}




-(void)configurationVariableSet:(id)val forName:(NSString *)forName
{
    [_config_dict setObject:val forKey:forName];
}

-(id)configurationVariableGet:(NSString *)forName
{
    return [_config_dict objectForKey:forName];
}

-(id)configurationVariableRemove:(NSString *)forName
{
    id ret = [_config_dict objectForKey:forName];
    [_config_dict removeObjectForKey:forName];
    return ret;
}


-(NSMutableDictionary *)buildKeychainQuery
{
    NSString *useServiceName = [NSString stringWithFormat:@"CocoaSplit-%@", self.serviceName];
    NSMutableDictionary *keyChainAttrs = [[NSMutableDictionary alloc] init];
    [keyChainAttrs setObject:(__bridge NSString *)kSecClassGenericPassword forKey:(__bridge NSString *)kSecClass];
    [keyChainAttrs setObject:useServiceName forKey:(__bridge NSString *)kSecAttrService];
    [keyChainAttrs setObject:self.accountName forKey:(__bridge NSString *)kSecAttrAccount];
    [keyChainAttrs setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge NSString *)kSecAttrAccessible];
    return keyChainAttrs;
}


-(void)loadFromKeychain
{
    NSLog(@"ACCOUNT NAME %@", self.accountName);
    
    if (!self.useKeychain || !self.accountName || !self.serviceName)
    {
        return;
    }

    NSMutableDictionary *keyChainAttrs = [self buildKeychainQuery];

    [keyChainAttrs setObject:(id)kCFBooleanTrue forKey:(__bridge NSString *)kSecReturnData];
    [keyChainAttrs setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge NSString *)kSecMatchLimit];
    
    NSLog(@"QUERY %@", keyChainAttrs);
    
    CFDataRef keyData = NULL;
    
    if (!SecItemCopyMatching((__bridge CFDictionaryRef)keyChainAttrs, (CFTypeRef *)&keyData))
    {
        if (keyData)
        {
            NSDictionary *storedData = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
            NSLog(@"STORED DATA %@", storedData);
            
            if (storedData)
            {
                self.accessToken = storedData[@"accessToken"];
                self.refreshToken = storedData[@"refreshToken"];
                self.expireDate = storedData[@"expireDate"];
                
            }
            CFRelease(keyData);
        }
        
    }
}


-(void)saveToKeychain:(NSString *)accountName
{
    self.accountName = accountName;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self saveToKeychain];
    });
}


-(void)saveToKeychain
{
    if (!self.useKeychain || !self.accountName)
    {
        return;
    }
    
    NSMutableDictionary *keyChainAttrs = [self buildKeychainQuery];
    
    NSMutableDictionary *keyDataDict = [[NSMutableDictionary alloc] init];
    [keyDataDict setObject:self.accessToken forKey:@"accessToken"];
    if (self.refreshToken)
    {
        [keyDataDict setObject:self.refreshToken forKey:@"refreshToken"];

    }
  
    if (self.expireDate)
    {
        [keyDataDict setObject:self.expireDate forKey:@"expireDate"];
   
    }
    
    NSData *keyData = [NSKeyedArchiver archivedDataWithRootObject:keyDataDict];
    [keyChainAttrs setObject:keyData forKey:(__bridge NSString *)kSecValueData];
    

    OSStatus addRes =  SecItemAdd((__bridge CFDictionaryRef)keyChainAttrs, NULL);
    
    if (addRes == errSecDuplicateItem)
    {
        SecItemDelete((__bridge CFDictionaryRef)keyChainAttrs);
        SecItemAdd((__bridge CFDictionaryRef)keyChainAttrs, NULL);
        
    }
}



-(NSString *)buildQueryString:(NSDictionary *)params
{
    NSMutableArray *paramParts = [[NSMutableArray alloc] init];
    
    for (NSString *pname in params)
    {
        NSString *pval = params[pname];
        NSString *equalString = [NSString stringWithFormat:@"%@=%@", pname, [pval stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [paramParts addObject:equalString];
    }
    
    return [paramParts componentsJoinedByString:@"&"];
}


-(void)buildAuthURL
{
    //NSQueryItems is 10.10+, so we can't use it :/
    
    NSString *authLocation = [self configurationVariableGet:kCSOauth2ConfigAuthURL];
    
    if (!authLocation)
    {
        return;
    }
    
    NSURLComponents *urlComponent = [NSURLComponents componentsWithString:authLocation];
    
    NSMutableArray *paramParts = [[NSMutableArray alloc] init];
    
    NSString *response_type = nil;
    
    if ([self.flowType isEqualToString:kCSOauth2CodeFlow])
    {
        response_type = @"code";
    } else if ([self.flowType isEqualToString:kCSOauth2ImplicitGrantFlow]) {
        response_type = @"token";
    }
    
    
    [paramParts addObject:[NSString stringWithFormat:@"response_type=%@", response_type]];
    
    [paramParts addObject:[NSString stringWithFormat:@"client_id=%@", self.clientID]];
    
    NSString *redirectURL = [self configurationVariableGet:kCSOauth2ConfigRedirectURL];
    
    if (redirectURL)
    {
        [paramParts addObject:[NSString stringWithFormat:@"redirect_uri=%@", redirectURL]];
    }
    
    
    NSArray *authScopes = [self configurationVariableGet:kCSOauth2ConfigScopes];
    
    if (authScopes)
    {
        NSString *scopeValue = [authScopes componentsJoinedByString:@" "];
        [paramParts addObject:[NSString stringWithFormat:@"scope=%@", scopeValue]];
    }
    
    NSDictionary *extraAuthParams = [self configurationVariableGet:kCSOauth2ExtraAuthParams];
    
    if (extraAuthParams)
    {
        for(NSString *key in extraAuthParams)
        {
            NSString *val = extraAuthParams[key];
            [paramParts addObject:[NSString stringWithFormat:@"%@=%@", key,val]];
        }
    }
    
    
    NSString *paramString = [paramParts componentsJoinedByString:@"&"];
    
    urlComponent.query = paramString;
    

    self.authURL = urlComponent.URL;
}


-(bool)doesTokenNeedRefresh
{
    
    NSLog(@"EXPIRE DATE %@", self.expireDate);
    
    if (!self.expireDate)
    {
        return NO;
    }
    
    NSDate *nowDate = [NSDate date];
    
    NSLog(@"NOW DATE %@", nowDate);
    
    if ([nowDate compare:self.expireDate] == NSOrderedDescending)
    {
        return YES;
    }
    
    return NO;
}


-(void)authorize:(void (^)(bool success))authCallback
{
    
    bool doAuth = NO;
    
    if (!self.forceVerify)
    {
        [self loadFromKeychain];
        if ([self doesTokenNeedRefresh])
        {
            _authorizeCallback = authCallback;
            [self refreshAccessToken];
            return;
        }
        
        if (self.accessToken)
        {
            doAuth = NO;
        } else {
            doAuth = YES;
        }
    } else {
        doAuth = YES;
    }
    
    if (doAuth)
    {
        _authorizeCallback = authCallback;

        [self buildAuthURL];
        
        NSLog(@"AUTHORIZATION URL IS %@", self.authURL);
        
        NSRect winFrame = NSMakeRect(0, 0, 1000, 1000);
        _authWebView = [[WebView alloc] initWithFrame:winFrame frameName:nil groupName:nil];
        _authWebView.policyDelegate = self;
        
        _authWindow = [[NSWindow alloc] initWithContentRect:winFrame styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        [_authWindow center];
        [_authWindow setContentView:_authWebView];
        [_authWindow makeKeyAndOrderFront:NSApp];
        [[_authWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:self.authURL]];
    } else {
        if (authCallback)
        {
            NSLog(@"CALLING AUTH CALLBACK FROM AUTHORIZE");
            authCallback(!!self.accessToken);
        }
    }

}


-(void)closeAuthWindow
{
    _authWindow = nil;
}

-(void)refreshAccessToken
{
    NSString *refreshLocation = [self configurationVariableGet:kCSOauth2AccessRefreshURL];
    NSString *clientSecret = [self configurationVariableGet:kCSOauth2ClientSecret];
    NSString *redirectURL = [self configurationVariableGet:kCSOauth2ConfigRedirectURL];
    
    
    NSLog(@"DOING REFRESH LOC %@ SEC %@ REDIR %@ REFRESH %@", refreshLocation, clientSecret, redirectURL, self.refreshToken);
    if (!refreshLocation || !clientSecret || !redirectURL || !self.refreshToken)
    {
        return;
    }
    
    
    NSURL *locationURL = [NSURL URLWithString:refreshLocation];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:locationURL];
    request.HTTPMethod = @"POST";
    
    NSDictionary *queryDict = @{@"grant_type": @"refresh_token",
                                @"client_id": self.clientID,
                                @"refresh_token": self.refreshToken,
                                @"client_secret": clientSecret };
    
    NSString *queryString = [self buildQueryString:queryDict];
    request.HTTPBody = [queryString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                       NSError *jsonError;
                                                       NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                                                       
                                                       self.accessToken = tokenData[@"access_token"];
                                                       NSNumber *expire_seconds = tokenData[@"expires_in"];
                                                       self.expireDate = [NSDate dateWithTimeIntervalSinceNow:expire_seconds.integerValue];
                                                       if (_authorizeCallback)
                                                       {
                                                           _authorizeCallback(!!self.accessToken);
                                                       }
                                                       
                                                       
                                                   }];
    
    [dataTask resume];

    
}
-(void)requestAccessToken:(NSString *)forCode
{
    
    NSLog(@"GET ACCESS TOKEN FOR %@", forCode);
    
    NSString *tokenLocation = [self configurationVariableGet:kCSOauth2AccessTokenRequestURL];
    NSString *clientSecret = [self configurationVariableGet:kCSOauth2ClientSecret];
    NSString *redirectURL = [self configurationVariableGet:kCSOauth2ConfigRedirectURL];
    
    
    if (!tokenLocation || !clientSecret || !redirectURL)
    {
        return;
    }
    
    
    NSURL *locationURL = [NSURL URLWithString:tokenLocation];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:locationURL];
    request.HTTPMethod = @"POST";
    
    NSDictionary *queryDict = @{@"grant_type": @"authorization_code",
                                @"code": forCode,
                                @"redirect_uri": redirectURL,
                                @"client_id": self.clientID,
                                @"client_secret": clientSecret };
    
    NSString *queryString = [self buildQueryString:queryDict];
    request.HTTPBody = [queryString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSession *urlSession = [NSURLSession sharedSession];

    NSLog(@"DOING ACCESS %@", request);
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                       NSError *jsonError;
                                                       NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                                                       
                                                       NSLog(@"TOKEN DATA IS %@", tokenData);
                                                       
                                                       self.accessToken = tokenData[@"access_token"];
                                                       self.refreshToken = tokenData[@"refresh_token"];
                                                       NSNumber *expire_seconds = tokenData[@"expires_in"];
                                                       self.expireDate = [NSDate dateWithTimeIntervalSinceNow:expire_seconds.integerValue];
                                                       if (_authorizeCallback)
                                                       {
                                                           _authorizeCallback(!!self.accessToken);
                                                           if (self.accountNameFetcher && self.useKeychain)
                                                           {
                                                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                                                   
                                                                   self.accountNameFetcher(self);
                                                                   
                                                               });
                                                           }
                                                       }

                                                       
                                                   }];
    
    [dataTask resume];

    
    
    
    
}
-(NSString *)extractCodeFromURL:(NSURL *)url
{
    NSString *query = url.query;
    
    for (NSString *param in [query componentsSeparatedByString:@"&"])
    {
        NSArray *pparts = [param componentsSeparatedByString:@"="];
        if (pparts.count < 2)
        {
            //what?
            continue;
        }
        
        NSString *pname = pparts.firstObject;
        NSString *pvalue = pparts.lastObject;
        
        if ([pname isEqualToString:@"code"])
        {
            return pvalue;
        }
    }
    return nil;
}



-(NSString *)extractAccessTokenFromURL:(NSURL *)url
{
    NSURLComponents *urlComp = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *urlFragment = urlComp.percentEncodedFragment;
    
    NSURLComponents *fakeComponents = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"http://localhost/blah?%@", urlFragment]];
    
    NSArray *queryVars = fakeComponents.queryItems;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", @"access_token"];
    NSURLQueryItem *tokenItem = [queryVars filteredArrayUsingPredicate:predicate].firstObject;
    
    return tokenItem.value;
}


-(bool)isURLRedirect:(NSURL *)testurl
{
    
    
    NSString *redirectURL = [self configurationVariableGet:kCSOauth2ConfigRedirectURL];
    
    NSLog(@"TESTING REDIRECT %@ AGAINST %@", redirectURL, testurl);
    if (!redirectURL)
    {
        return NO;
    }
    
    NSURLComponents *testComp = [NSURLComponents componentsWithURL:testurl resolvingAgainstBaseURL:NO];
    NSURLComponents *redirectComp = [NSURLComponents componentsWithString:redirectURL];
    
    if (![testComp.scheme isEqualToString:redirectComp.scheme])
    {
        return NO;
    }
    
    if (![testComp.host isEqualToString:redirectComp.host])
    {
        return NO;
    }
    
    NSString *testPath = testComp.path;
    NSString *rePath = redirectComp.path;
    
    if ([testPath isEqualToString:rePath])
    {
        return YES;
    }
    
    return NO;
}


-(void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    
    NSURL *reqUrl = request.URL;
    NSString *redirectURL = [self configurationVariableGet:kCSOauth2ConfigRedirectURL];
    
    if (reqUrl && redirectURL)
    {
        
        
        
        if ([self isURLRedirect:reqUrl])
        {
            [listener ignore];
            NSLog(@"REQ URL %@", reqUrl);
            
            if ([self.flowType isEqualToString:kCSOauth2ImplicitGrantFlow])
            {
                self.accessToken = [self extractAccessTokenFromURL:reqUrl];
                if (_authorizeCallback)
                {
                    _authorizeCallback(!!self.accessToken);
                    if (self.accountNameFetcher && self.useKeychain)
                    {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            
                            self.accountNameFetcher(self);
                            
                        });
                    }
                }
            } else if ([self.flowType isEqualToString:kCSOauth2CodeFlow]) {
                NSString *flowCode = [self extractCodeFromURL:reqUrl];
                [self requestAccessToken:flowCode];
            }
            [self closeAuthWindow];
        }
    }
    
    [listener use];
}





-(void)authorizedJsonRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(id decodedData))handler
{
    //Set OAuth Bearer header
    
    NSString *authType;
    
    if ([self.flowType isEqualToString:kCSOauth2ImplicitGrantFlow])
    {
        authType = @"OAuth";
    } else if ([self.flowType isEqualToString:kCSOauth2CodeFlow]) {
        authType = @"Bearer";
    }
    
    
    
    [request setValue:[NSString stringWithFormat:@"%@ %@", authType, self.accessToken] forHTTPHeaderField:@"Authorization"];

    NSURLSession *urlSession = [NSURLSession sharedSession];
    
    NSLog(@"CALLING REQUEST %@", request);
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSError *jsonError;
            id json_object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            if (handler)
            {
                handler(json_object);
            }
        }];
    
    [dataTask resume];
}

-(void)jsonRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(id decodedData))handler
{
    [self authorize:^(bool success) {
        if (success)
        {
            [self authorizedJsonRequest:request completionHandler:handler];
        }
        
    }];
}


@end
