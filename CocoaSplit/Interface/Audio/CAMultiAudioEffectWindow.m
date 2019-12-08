//
//  CAMultiAudioEffectWindow.m
//  CocoaSplit
//
//  Created by Zakk on 1/1/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import "CAMultiAudioEffectWindow.h"

@implementation CAMultiAudioEffectWindow


-(instancetype)initWithAudioNode:(CAMultiAudioNode *)node
{
    self.audioUnitView = [node audioUnitNSView];
    if (!self.audioUnitView)
    {
        return nil;
    }
    
    NSRect contentRect = NSMakeRect(0, 0, self.audioUnitView.frame.size.width, self.audioUnitView.frame.size.height);
    if (self = [super initWithContentRect:contentRect styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:YES])
    {
        
        self.level = NSNormalWindowLevel;
        [self setContentView:self.audioUnitView];
        
        self.title = node.name;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(auViewChangedSize:) name:NSViewFrameDidChangeNotification object:self.audioUnitView];
        
    }
    
    return self;
}


-(void)auViewChangedSize:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.audioUnitView];
    

    NSSize oldSize = [self contentRectForFrameRect:self.frame].size;
    NSSize newSize = self.audioUnitView.frame.size;
    
    NSRect wFrame = self.frame;
    
    float dy = oldSize.height - newSize.height;
    float dx = oldSize.width - newSize.width;
    
    wFrame.origin.y += dy;
    wFrame.origin.x += dx;
    wFrame.size.height -= dy;
    wFrame.size.width -= dx;
    [self setFrame:wFrame display:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(auViewChangedSize:) name:NSViewFrameDidChangeNotification object:self.audioUnitView];

}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.audioUnitView];
}


@end
