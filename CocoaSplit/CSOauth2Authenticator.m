//
//  CSOauth2Authenticator.m
//  CocoaSplit
//
//  Created by Zakk on 7/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSOauth2Authenticator.h"

@implementation CSOauth2Authenticator


-(instancetype) initWithServiceName:(NSString *)serviceName authLocation:(NSString *)auth_location clientID:(NSString *)client_id redirectURL:(NSString *)redirect_url authScopes:(NSArray *)scopes forceVerify:(bool)force_verify useKeychain:(bool)use_keychain
{
    if (self = [self init])
    {
        self.serviceName = serviceName;
        self.authLocation = auth_location;
        self.clientID = client_id;
        self.redirectURL = redirect_url;
        self.authScopes = scopes;
        self.forceVerify = force_verify;
        self.useKeychain = use_keychain;
    }
    
    return self;
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
    
    NSDictionary *keyDataDict = @{@"accessToken": self.accessToken};
    
    NSData *keyData = [NSKeyedArchiver archivedDataWithRootObject:keyDataDict];
    [keyChainAttrs setObject:keyData forKey:(__bridge NSString *)kSecValueData];
    

    OSStatus addRes =  SecItemAdd((__bridge CFDictionaryRef)keyChainAttrs, NULL);
    
    if (addRes == errSecDuplicateItem)
    {
        SecItemDelete((__bridge CFDictionaryRef)keyChainAttrs);
        SecItemAdd((__bridge CFDictionaryRef)keyChainAttrs, NULL);
        
    }
}



-(void)buildAuthURL
{
    //NSQueryItems is 10.10+, so we can't use it :/
    
    NSURLComponents *urlComponent = [NSURLComponents componentsWithString:self.authLocation];
    
    NSMutableArray *paramParts = [[NSMutableArray alloc] init];
    
    [paramParts addObject:@"response_type=token"];
    [paramParts addObject:[NSString stringWithFormat:@"client_id=%@", self.clientID]];
    [paramParts addObject:[NSString stringWithFormat:@"redirect_uri=%@", self.redirectURL]];
    
    NSString *scopeValue = [self.authScopes componentsJoinedByString:@" "];
    [paramParts addObject:[NSString stringWithFormat:@"scope=%@", scopeValue]];
    
    if (self.extraAuthParams)
    {
        for(NSString *key in self.extraAuthParams)
        {
            NSString *val = self.extraAuthParams[key];
            [paramParts addObject:[NSString stringWithFormat:@"%@=%@", key,val]];
        }
    }
    
    
    NSString *paramString = [paramParts componentsJoinedByString:@"&"];
    
    urlComponent.query = paramString;
    

    self.authURL = urlComponent.URL;
}


-(void)authorize:(void (^)(bool success))authCallback
{
    
    bool doAuth = NO;
    
    if (!self.accessToken)
    {
        
        
        if (!self.forceVerify)
        {
            [self loadFromKeychain];
            if (self.accessToken)
            {
                doAuth = NO;
            } else {
                doAuth = YES;
            }
        }
    }
    
    if (self.forceVerify)
    {
        doAuth = YES;
    }
    
    _authorizeCallback = authCallback;
    if (doAuth)
    {
        if (!self.authURL)
        {
            [self buildAuthURL];
        }
        
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
            authCallback(!!self.accessToken);
        }
    }

}


-(void)closeAuthWindow
{
    _authWindow = nil;
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
    NSURLComponents *testComp = [NSURLComponents componentsWithURL:testurl resolvingAgainstBaseURL:NO];
    NSURLComponents *redirectComp = [NSURLComponents componentsWithString:self.redirectURL];
    
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
    if (reqUrl && self.redirectURL)
    {
        
        
        
        if ([self isURLRedirect:reqUrl])
        {
            [listener ignore];
            self.accessToken = [self extractAccessTokenFromURL:reqUrl];
            [self closeAuthWindow];
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
        }
    }
    
    [listener use];
}





-(void)authorizedJsonRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(id decodedData))handler
{
    //Set OAuth Bearer header
    
    
    [request setValue:[NSString stringWithFormat:@"OAuth %@", self.accessToken] forHTTPHeaderField:@"Authorization"];

    NSURLSession *urlSession = [NSURLSession sharedSession];
    
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
    if (!self.accessToken)
    {
        [self authorize:^(bool success) {
            if (success)
            {
                [self authorizedJsonRequest:request completionHandler:handler];
            }
            
        }];
    } else {
        [self authorizedJsonRequest:request completionHandler:handler];

    }
}


@end
