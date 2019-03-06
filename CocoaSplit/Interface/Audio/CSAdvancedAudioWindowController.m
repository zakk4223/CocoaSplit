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
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}











- (IBAction)addAudioTrack:(id)sender
{
    [self.audioEngine addOutputTrack];
}
- (IBAction)removeAudioTrack:(id)sender
{
    NSArray *selectedTracks = self.outputTracksController.selectedObjects;
    for (NSDictionaryControllerKeyValuePair *kvp in selectedTracks)
    {
        NSString *trackName = kvp.key;
        [self.audioEngine removeOutputTrack:trackName];
    }
}

@end
