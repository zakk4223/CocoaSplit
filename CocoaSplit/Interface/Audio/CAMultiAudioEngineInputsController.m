//
//  CAMultiAudioEngineInputsController.m
//  CocoaSplit
//
//  Created by Zakk on 1/4/18.

#import "CAMultiAudioEngineInputsController.h"
#import "CAMultiAudioNode.h"
#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioFile.h"
#import "CAMultiAudioEngine.h"

@interface CAMultiAudioEngineInputsController ()

@end

@implementation CAMultiAudioEngineInputsController

-(void)awakeFromNib
{
    if (!_mixerWindows)
    {
        _mixerWindows = [NSMutableDictionary dictionary];
    }
    [super awakeFromNib];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


-(void)openMixerWindow:(CAMultiAudioNode *)node
{
    
    
    if (node)
    {
        CAMultiAudioMatrixMixerWindowController *mixerWindow = [[CAMultiAudioMatrixMixerWindowController alloc] initWithAudioMixer:node];
        [mixerWindow showWindow:nil];

        mixerWindow.window.title = node.name;
        mixerWindow.window.identifier = node.nodeUID;
        mixerWindow.window.delegate = self;
        
        [_mixerWindows setObject:mixerWindow forKey:node.nodeUID];
    }
    
}

-(void)windowWillClose:(NSNotification *)notification
{
    NSWindow *closedWindow = notification.object;
    
    if (closedWindow.identifier)
    {
        [_mixerWindows removeObjectForKey:closedWindow.identifier];
    }
}

-(void)removeFileAudio:(CAMultiAudioFile *)toDelete
{
    CAMultiAudioEngine *engine = self.multiAudioEngineController.content;
    
    [engine removeFileInput:toDelete];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CAMultiAudioNode *audioNode = [self.audioInputsController.arrangedObjects objectAtIndex:row];
    if ([audioNode isKindOfClass:CAMultiAudioFile.class])
    {
        return [tableView makeViewWithIdentifier:@"fileAudioView" owner:self];
    } else {
        return [tableView makeViewWithIdentifier:@"standardAudioView" owner:self];
    }
}

@end
