//
//  CSWebViewCapture.m
//  CSWebViewCapturePlugin
//
//  Created by Zakk on 7/21/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSWebViewCapture.h"
#import <SceneKit/SceneKit.h>

@implementation CSWebViewCapture


+(NSString *)label
{
    return @"WebView";
}


-(CALayer *)createNewLayer
{
    if (!self.webView)
    {
        self.webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
        self.webView.wantsLayer = YES;
        self.webWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 500, 500) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        [self.webWindow.contentView addSubview:self.webView];
        [self.webWindow makeKeyAndOrderFront:NSApp];

        self.webScene = [SCNScene scene];
        self.cameraNode = [SCNNode node];
        [self.webScene.rootNode addChildNode:self.cameraNode];
        self.cameraNode.position = SCNVector3Make(250, 250, 500);
        self.cameraNode.camera.zFar = 10000;
        self.cameraNode.camera.xFov = ((atan(250/500)*180/M_PI)*2);
        self.cameraNode.camera.xFov = ((atan(250/500)*180/M_PI)*2);
        self.webNode = [SCNNode node];
        self.webNode.geometry = [SCNPlane planeWithWidth:500 height:500];
        CALayer *testLayer = [CALayer layer];
        testLayer.backgroundColor = [NSColor greenColor].CGColor;
        testLayer.bounds = CGRectMake(0, 0, 500, 500);
        self.webNode.geometry.firstMaterial.diffuse.contents = self.webView.layer;
        NSLog(@"LAYER BOUNDS %@", NSStringFromRect(self.webView.layer.bounds));
        self.webNode.position = SCNVector3Make(250, 250, 0);
        [self.webScene.rootNode addChildNode:self.webNode];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.cocoasplit.com"]]];

    }
    
    SCNLayer *layer = [SCNLayer layer];
    layer.scene = self.webScene;
    return layer;
}




@end
