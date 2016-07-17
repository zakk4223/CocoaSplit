//
//  TwitchStreamServiceViewController.m
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "TwitchStreamServiceViewController.h"


@interface TwitchStreamServiceViewController ()

@end

@implementation TwitchStreamServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
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


- (IBAction)doTwitchAuth:(id)sender
{
 
    NSURL *authURL = [NSURL URLWithString:@"https://api.twitch.tv/kraken/oauth2/authorize?response_type=token&force_verify=true&client_id=p2onxyxk17dlngdgtj43kl9gaj2yb2a&redirect_uri=cocoasplit-twitch://cocoasplit.com/oauth/redirect&scope=channel_read"];
    
    
    NSRect winFrame = NSMakeRect(0, 0, 1000, 1000);
    self.authWebView = [[WebView alloc] initWithFrame:winFrame frameName:nil groupName:nil];
    self.authWebView.policyDelegate = self;
    
    self.authWindow = [[NSWindow alloc] initWithContentRect:winFrame styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    [self.authWindow center];
    [self.authWindow setContentView:self.authWebView];
    [self.authWindow makeKeyAndOrderFront:NSApp];
    [[self.authWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:authURL]];
    
}


-(void)closeAuthWindow
{
    self.authWindow = nil;
}


-(void)receivedOAuth:(NSString *)oToken
{
    self.serviceObj.oAuthKey = oToken;
    [self.serviceObj fetchTwitchStreamKey];
    
}


-(void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSURL *reqUrl = request.URL;
    if (reqUrl)
    {
        if ([reqUrl.scheme isEqualToString:@"cocoasplit-twitch"])
        {
            [listener ignore];
            NSString *accessToken = [self extractAccessTokenFromURL:reqUrl];
            [self receivedOAuth:accessToken];
            [self closeAuthWindow];

        }
    }

    [listener use];
}

@end
