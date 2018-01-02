//
//  CAMultiAudioEffectWindow.h
//  CocoaSplit
//
//  Created by Zakk on 1/1/18.
//

#import <Cocoa/Cocoa.h>
#import "CAMultiAudioNode.h"


@interface CAMultiAudioEffectWindow : NSWindow
{
    NSView *_audioUnitView;
}

-(instancetype)initWithAudioNode:(CAMultiAudioNode *)node;
@property (strong) NSView *audioUnitView;

@end
