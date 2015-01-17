//
//  AWRenderer.m
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/2/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "AWRenderer.h"

@implementation AWRenderer


-(instancetype) initWithIOSurface:(IOSurfaceRef)ioSurf
{
    if (self = [super init])
    {
        _renderSurface = ioSurf;
    }
}


-(void)setupWebView
{
    if (!_renderSurface)
    {
        return;
    }
    _webCore = Awesomium::WebCore::Initialize(Awesomium::WebConfig());
    _webView = _webCore->CreateWebView(IOSurfaceGetWidth(_renderSurface), IOSurfaceGetHeight(_renderSurface));
}

-(void)loadURL:(NSString *)url
{
    if (!_webView)
    {
        return;
    }
    _myURL = url;
    Awesomium::WebURL awURL(WSLit(url.UTF8String));
    
    _webView->LoadURL(awURL);
}

-(void)update
{
    if (!_webCore)
    {
        return;
    }
    
    _webCore->Update();
}

@end
