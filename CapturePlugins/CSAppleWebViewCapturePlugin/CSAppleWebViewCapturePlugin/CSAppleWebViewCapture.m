//
//  CSAppleWebViewCapture.m
//  CSAppleWebViewCapturePlugin
//
//  Created by Zakk on 11/3/18.
//

#import "CSAppleWebViewCapture.h"

@implementation CSAppleWebViewCapture
@synthesize webURL = _webURL;
@synthesize browser_height = _browser_height;
@synthesize browser_width = _browser_width;


+(bool)shouldLoad
{
    if (@available(macOS 10.13, *))
    {
        return YES;
    }
    return NO;
}


-(instancetype) init
{
    
    if (self = [super init])
    {
        self.browser_width = 1280;
        self.browser_height = 720;
    }
    
    return self;
}


-(NSString *)webURL
{
    return _webURL;
}

-(void)setWebURL:(NSString *)webURL
{
    _webURL = webURL;
    if (!self.webView)
    {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKPreferences *webPrefs = [[WKPreferences alloc] init];
        webPrefs.plugInsEnabled = YES;
        webPrefs.javaScriptEnabled = YES;
        if (@available(macOS 10.12, *))
        {
            config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        }
        
        config.preferences = webPrefs;
        self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.browser_width, self.browser_height) configuration:config];
        self.webView.navigationDelegate = self;
        self.webView.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
    
    if (!_frameSemaphore)
    {
        _frameSemaphore = dispatch_semaphore_create(1);
    }
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webURL]]];
}

-(NSSize) captureSize
{
    return NSMakeSize(self.browser_width, self.browser_height);
}


+(NSString *)label
{
    return @"Browser Capture (Apple)";
}

-(void)setBrowser_width:(int)browser_width
{
    _browser_width = browser_width;
    [self resizeWebView];
}

-(int) browser_width
{
    return _browser_width;
}

-(void)setBrowser_height:(int)browser_height
{
    _browser_height = browser_height;
    [self resizeWebView];
}

-(int) browser_height
{
    return _browser_height;
}


-(void)resizeWebView
{
    if (self.webView)
    {
        NSRect currentFrame = self.webView.frame;
        currentFrame.size.width = self.browser_width;
        currentFrame.size.height = self.browser_height;
        [self.webView setFrame:currentFrame];
    }
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    
    [self.webView setValue:@NO forKey:@"drawsBackground"];
    NSString *captureName = self.webView.title;
    if (!captureName || captureName.length == 0)
    {
        captureName = self.webURL;
    }
    
    self.captureName = captureName;
}


-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"FAILED NAVIGATION WITH %@", error.localizedDescription);
}


-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    [aCoder encodeObject:self.webURL forKey:@"webURL"];
    [aCoder encodeInt:self.browser_width forKey:@"browser_width"];
    [aCoder encodeInt:self.browser_height forKey:@"browser_height"];
}


-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    self.browser_width = [aDecoder decodeIntForKey:@"browser_width"];
    self.browser_height = [aDecoder decodeIntForKey:@"browser_height"];
    self.webURL = [aDecoder decodeObjectForKey:@"webURL"];
}

-(void)frameTick
{


    if (self.webView)
    {
        if (!dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_NOW))
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                

                [self->_webView takeSnapshotWithConfiguration:nil completionHandler:^(NSImage * _Nullable snapshotImage, NSError * _Nullable error) {
                    [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                        layer.contents = snapshotImage;
                    }];
                    dispatch_semaphore_signal(self->_frameSemaphore);
                }];
            });
        }
    }
    

}


@end
