//
//  CSAdvancedAudioWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//

#import "CSAdvancedAudioWindowController.h"

@interface CSAdvancedAudioWindowController ()

@end

@implementation CSAdvancedAudioWindowController



-(instancetype) init
{
    return [self initWithWindowNibName:@"CSAdvancedAudioWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    self.effectsController.audioNode = self.controller.multiAudioEngine.encodeMixer;
    [self.controller addObserver:self forKeyPath:@"multiAudioEngine.encodeMixer" options:NSKeyValueObservingOptionNew context:nil];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}



-(void)windowWillClose:(NSNotification *)notification
{
    NSWindow *closingWindow = [notification object];
}


-(void)dealloc
{
    [self.controller removeObserver:self forKeyPath:@"multiAudioEngine.encodeMixer"];

}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ((object == self.controller) && [keyPath isEqualToString:@"multiAudioEngine.encodeMixer"])
    {
        self.effectsController.audioNode = self.controller.multiAudioEngine.encodeMixer;
    }
}



@end
