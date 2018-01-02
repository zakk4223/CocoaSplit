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
    _audioUnitView = [node audioUnitNSView];
    if (!_audioUnitView)
    {
        return nil;
    }
    
    NSRect contentRect = NSMakeRect(0, 0, _audioUnitView.frame.size.width, _audioUnitView.frame.size.height);
    if (self = [super initWithContentRect:contentRect styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES])
    {
        
        self.level = NSNormalWindowLevel;
        [self setContentView:_audioUnitView];
        
        self.title = node.name;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(auViewChangedSize:) name:NSViewFrameDidChangeNotification object:_audioUnitView];
        
    }
    
    return self;
}


-(void)auViewChangedSize:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_audioUnitView];
    

    NSSize oldSize = [self contentRectForFrameRect:self.frame].size;
    NSSize newSize = _audioUnitView.frame.size;
    
    NSRect wFrame = self.frame;
    
    float dy = oldSize.height - newSize.height;
    float dx = oldSize.width - newSize.width;
    
    wFrame.origin.y += dy;
    wFrame.origin.x += dx;
    wFrame.size.height -= dy;
    wFrame.size.width -= dx;
    [self setFrame:wFrame display:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(auViewChangedSize:) name:NSViewFrameDidChangeNotification object:_audioUnitView];

}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_audioUnitView];
}


@end
