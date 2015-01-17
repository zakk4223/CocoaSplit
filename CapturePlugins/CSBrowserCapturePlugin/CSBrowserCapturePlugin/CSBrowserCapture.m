//
//  CSBrowserCapture.m
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/1/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSBrowserCapture.h"

@implementation CSBrowserCapture
@synthesize url = _url;


-(void)setUrl:(NSString *)url
{
    _url = url;
    
    if (!_renderQueue)
    {
        _renderQueue = dispatch_queue_create("Browser Render Queue", NULL);
        _render_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _renderQueue);
        
        //20FPS test
        dispatch_source_set_timer(_render_timer, DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC, 0);
        
        __block typeof(self) blockSelf = self;
        
        dispatch_source_set_event_handler(_render_timer, ^{
            [blockSelf renderLayer];
        });
        dispatch_resume(_render_timer);

    }
    if (!_webWindow)
    {
        NSRect frame = NSMakeRect(-16000.0, -16000.0, 1920.0, 1080.0);
        
        _webWindow = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [_webWindow setFrame:frame display:NO];
        _webWindow.movable = NO;
        _webWindow.hasShadow = NO;
        
    }
    if (!_webview)
    {
        _webview = [[WebView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 1920.0, 1080.0) frameName:nil groupName:nil];
        _webview.shouldUpdateWhileOffscreen = YES;
        _webview.shouldCloseWithWindow = YES;
        _webview.frameLoadDelegate = self;
        
        _webWindow.contentView = _webview;
    }
    
    if (!_cgcontext)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        _cgcontext = CGBitmapContextCreate(NULL, 1920, 1080, 8, 1920*4, colorSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
    }
    _contentLoaded = NO;
    _webview.mainFrameURL = url;
}

-(void)webView:(WebView *)wView didFinishLoadForFrame:(WebFrame *)frame
{
    _contentLoaded = YES;
}


-(void)renderLayer
{
    
    if (!_contentLoaded)
    {
        return;
    }
    
    
    if (!_webview)
    {
        return;
    }
    
    
    NSView *myView = _webWindow.contentView;
    
    
    if (!myView)
    {
        return ;
    }
    
    
    
    
    
    NSBitmapImageRep *bitmapRep;

    bitmapRep = [myView bitmapImageRepForCachingDisplayInRect:myView.bounds];
    [myView cacheDisplayInRect:myView.bounds toBitmapImageRep:bitmapRep];
    
    _currentImage = [[CIImage alloc] initWithBitmapImageRep:bitmapRep];
}

-(CIImage *)currentImage
{
    return _currentImage;
}



-(NSString *)url
{
    return _url;
}

+(NSString *)label
{
    return @"Browser Source";
}
@end
