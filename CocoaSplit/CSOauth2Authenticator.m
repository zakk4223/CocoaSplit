//
//  CSOauth2Authenticator.m
//  CocoaSplit
//
//  Created by Zakk on 7/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSOauth2Authenticator.h"

@implementation CSOauth2Authenticator


-(instancetype) initWithServiceName:(NSString *)serviceName authLocation:(NSString *)auth_location clientID:(NSString *)client_id redirectURL:(NSString *)redirect_url authScopes:(NSArray *)scopes forceVerify:(bool)force_verify
{
    if (self = [self init])
    {
        self.serviceName =
        self.authLocation = auth_location;
        self.clientID = client_id;
        self.redirectURL = redirect_url;
        self.authScopes = scopes;
        self.forceVerify = force_verify;
        
    }
    
    return self;
}


-(void)buildAuthURL
{
    //NSQueryItems is 10.10+, so we can't use it :/
    
    NSURLComponents *urlComponent = [NSURLComponents componentsWithString:self.authLocation];
    
    NSMutableArray *paramParts = [[NSMutableArray alloc] init];
    
    [paramParts addObject:@"response_type=token"];
    [paramParts addObject:[NSString stringWithFormat:@"client_id=%@", self.clientID]];
    [paramParts addObject:[NSString stringWithFormat:@"redirect_uri=%@", self.redirectURL]];
    
    NSString *scopeValue = [self.authScopes componentsJoinedByString:@","];
    [paramParts addObject:[NSString stringWithFormat:@"scope=%@", scopeValue]];
    
    NSString *paramString = [paramParts componentsJoinedByString:@"&"];
    
    urlComponent.query = paramString;
    

    self.authURL = urlComponent.URL;
}


-(void)authorize:(void (^)(bool success))authCallback
{
    
    _authorizeCallback = authCallback;
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
    if (!self.authURL)
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
