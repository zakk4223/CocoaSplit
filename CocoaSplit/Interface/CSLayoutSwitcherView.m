//
//  CSLayoutSwitcherView.m
//  CocoaSplit
//
//  Created by Zakk on 3/6/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutSwitcherView.h"
#import "CSPreviewGLLayer.h"

@implementation CSLayoutSwitcherView
@synthesize sourceLayout = _sourceLayout;





-(instancetype)init
{
    if (self = [super init])
    {
        [self setWantsLayer:YES];
        //self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    }
    
    return self;
}


-(CALayer *)makeBackingLayer
{
    CSPreviewGLLayer *newLayer = [CSPreviewGLLayer layer];
    return newLayer;
}

-(void)mouseDown:(NSEvent *)event
{
    self.layer.opacity = 0.5f;
}

-(void)mouseUp:(NSEvent *)event
{
    self.layer.opacity = 1.0f;
}


-(SourceLayout *)sourceLayout
{
    return _sourceLayout;
}


-(void)setSourceLayout:(SourceLayout *)sourceLayout
{
    _sourceLayout = sourceLayout;
    if (_sourceLayout)
    {
        CSPreviewGLLayer *newLayer = (CSPreviewGLLayer *)self.layer;
        newLayer.borderColor = [NSColor lightGrayColor].CGColor;
        newLayer.borderWidth = 1.0f;
        newLayer.doRender = YES;
        newLayer.renderer = [[LayoutRenderer alloc] init];
        newLayer.renderer.layout = _sourceLayout;
        [_sourceLayout restoreSourceList:nil];
        [self setNeedsDisplay:YES];
        
    }
}


@end
