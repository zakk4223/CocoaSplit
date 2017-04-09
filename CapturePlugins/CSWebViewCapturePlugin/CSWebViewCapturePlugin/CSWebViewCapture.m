//
//  CSWebViewCapture.m
//  CSWebViewCapturePlugin
//
//  Created by Zakk on 4/8/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSWebViewCapture.h"

@implementation CSWebViewCapture



-(instancetype) init
{
    if (self = [super init])
    {
        NSRect webRect = [NSWindow contentRectForFrameRect:NSMakeRect(0, 0, 1280, 720) styleMask:NSBorderlessWindowMask];
       //_webWindow = [[NSWindow alloc] initWithContentRect:webRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        _webView = [[CSWebViewView alloc] initWithFrame:webRect frameName:nil groupName:nil];
        _webView.policyDelegate = self;
        _webView.shouldUpdateWhileOffscreen = YES;
        _webView.drawsBackground = NO;
        
       //_webWindow.contentView = _webView;
        //_webView.wantsLayer = YES;
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://streamlabs.com/alert-box/v3/9B7286FAFF560075EB7B"]];
        //NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.rsdio.com/zakk/"]];

        [_webView.mainFrame loadRequest:req];
        
        //[_webWindow makeKeyAndOrderFront:NSApp];
        
    }
    return self;
}

-(void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSLog(@"REQUEST IS %@", request);
    [listener use];
}


+(NSString *)label
{
    return @"WebView";
}


-(CALayer *)createNewLayer
{
    return [CALayer layer];
}


-(void)frameTick
{
    /*
    if (!_imageRep)
    {
        _imageRep = [_webView bitmapImageRepForCachingDisplayInRect:_webView.frame];
    }
   NSImage *useImage = [[NSImage alloc] initWithSize:_imageRep.size];
[useImage addRepresentation:_imageRep];
    */
    dispatch_async(dispatch_get_main_queue(), ^{
        NSBitmapImageRep *myRep = [_webView bitmapImageRepForCachingDisplayInRect:_webView.frame];
        [_webView cacheDisplayInRect:_webView.frame toBitmapImageRep:myRep];

        NSImage *useImage = [[NSImage alloc] initWithSize:myRep.size];
        [useImage addRepresentation:myRep];

        //CGContextRef rCtx = CGBitmapContextCreate(NULL, 1280, 720, 8, 1280*8, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
        
        //[_webView.layer renderInContext:rCtx];


        [self updateLayersWithFramedataBlock:^(CALayer *layer) {

            layer.contents = useImage;
       }];
    });
}


@end
 
