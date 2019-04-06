//
//  CAMultiAudioMatrixMixerWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 6/7/15.
//

#import <Cocoa/Cocoa.h>
#import "CAMultiAudioDownmixer.h"
#import "CAMultiAudioInput.h"
#import "CAMultiAudioEffectsTableController.h"

@interface CAMultiAudioMatrixMixerWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>
{
    NSMenu *_tracksMenu;
}

@property (weak) IBOutlet NSTableView *matrixTable;
@property (strong) CAMultiAudioInput *audioNode;
@property (strong) CAMultiAudioDownmixer *downMixer;
@property (assign) UInt32 matrixRows;
@property (assign) UInt32 matrixColumns;
@property (strong) NSWindow *eqWindow;
@property (strong) NSWindow *compressorWindow;
@property (weak) IBOutlet CAMultiAudioEffectsTableController *effectsController;
@property (weak) NSObject *delegate;
@property (strong) IBOutlet NSDictionaryController *audioTracksDictionaryController;
@property (readonly) NSArray *trackSortDescriptors;

- (IBAction)matrixVolumeChanged:(NSSlider *)sender;

-(instancetype)initWithAudioMixer:(CAMultiAudioNode *)node;
-(IBAction)trackAddClicked:(NSButton *)sender;
- (IBAction)trackRemoveClicked:(id)sender;


@end
