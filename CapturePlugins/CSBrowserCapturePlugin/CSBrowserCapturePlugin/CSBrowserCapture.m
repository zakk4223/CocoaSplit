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
    
    if (!_webview)
    {
        _webview = [[WebView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 1920.0, 1080.0) frameName:nil groupName:nil];
        _webview.shouldUpdateWhileOffscreen = YES;
        _webview.shouldCloseWithWindow = YES;
        _webview.frameLoadDelegate = self;
        _webview.wantsLayer = YES;
        
        
    }
    
    _contentLoaded = NO;
    _webview.mainFrameURL = url;
}

-(void)webView:(WebView *)wView didFinishLoadForFrame:(WebFrame *)frame
{
    _contentLoaded = YES;
    [self updateLayersWithBlock:^(CALayer *layer) {
        NSLog(@"SET CONTENTS OF %@ TO %@", layer, ((CALayer *)_webview.layer.sublayers.firstObject).contents);
        
        layer.contents = _webview.layer.contents;
    }];

}



-(CALayer *)createNewLayer
{
    CALayer *newLayer = [CALayer layer];
    if (_webview)
    {
        newLayer.contents = _webview.layer.contents;
    }
    return newLayer;
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
