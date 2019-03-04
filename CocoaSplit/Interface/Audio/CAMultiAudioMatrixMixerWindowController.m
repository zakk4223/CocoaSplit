//
//  CAMultiAudioMatrixMixerWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 6/7/15.
//

#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioMatrixCell.h"
#import "CAMultiAudioUnit.h"
#import "CAMultiAudioEngine.h"
#import <AppKit/AppKit.h>



@interface NSObject(CAMultiAudioMixerWindowDelegate)
-(void)mixerWindowWillClose:(CAMultiAudioMatrixMixerWindowController *)mixerController;
@end


@interface CAMultiAudioMatrixMixerWindowController ()

@end

@implementation CAMultiAudioMatrixMixerWindowController


-(void)addTrackToInput:(NSMenuItem *)menuItem
{
    NSString *trackName = menuItem.representedObject;
    
    [self.audioNode addToOutputTrack:trackName];
}




-(void)buildTrackMenu
{
    NSDictionary *availableTracks = self.audioNode.engine.outputTracks;
    _tracksMenu = [[NSMenu alloc] init];
    
    for(NSString *trackName in availableTracks)
    {
        if (!self.audioNode.outputTracks[trackName])
        {
            NSMenuItem *tItem = [[NSMenuItem alloc] initWithTitle:trackName action:@selector(addTrackToInput:) keyEquivalent:@""];
            tItem.target = self;
            tItem.representedObject = trackName;
            [_tracksMenu addItem:tItem];
        }
    }
}


-(void)openAddTrackPopover:(id)sender sourceRect:(NSRect)sourceRect
{
    [self buildTrackMenu];
    
    NSInteger midItem = _tracksMenu.itemArray.count/2;
    NSPoint popupPoint = NSMakePoint(NSMaxY(sourceRect), NSMidY(sourceRect));
    [_tracksMenu popUpMenuPositioningItem:[_tracksMenu itemAtIndex:midItem] atLocation:popupPoint inView:sender];
    
}


-(IBAction)trackAddClicked:(NSButton *)sender
{
    NSRect sbounds = sender.bounds;
    
    [self openAddTrackPopover:sender sourceRect:sbounds];
}

- (IBAction)trackRemoveClicked:(id)sender
{
    NSArray *selectedTracks = self.audioTracksDictionaryController.selectedObjects;
    for (id trackInfo in selectedTracks)
    {
        NSString *trackName = [trackInfo key];
        [self.audioNode removeFromOutputTrack:trackName];
    }
}


- (IBAction)matrixVolumeChanged:(NSSlider *)sender
{
    UInt32 inputChannel = (UInt32)((sender.tag / 100) - 1 );
    UInt32 outputChannel = sender.tag % 100;
    
    [self.downMixer setVolume:[sender doubleValue] forChannel:inputChannel outChannel:outputChannel];
}


-(instancetype)initWithAudioMixer:(CAMultiAudioInput *)node
{
    if (self = [self initWithWindowNibName:@"CAMultiAudioMatrixMixerWindowController"])
    {
        self.audioNode = node;
        self.downMixer = node.downMixer;
        
        //NSView *audioView = [node audioUnitNSView];
       // NSLog(@"AUDIO VIEW SIZE %@", NSStringFromRect(audioView.frame));
        //self.window.contentView = audioView;
        
    }
    
    return self;
}










-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    
    return self.downMixer.inputChannelCount;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSInteger columnIndex = [self.matrixTable.tableColumns indexOfObject:tableColumn];


    if (columnIndex == 0)
    {
        NSTableCellView *inputLabel = [self.matrixTable makeViewWithIdentifier:@"MatrixLabelCell" owner:self];

        [inputLabel.textField setStringValue:[NSString stringWithFormat:@"Input Channel %ld", (long)row]];
        [inputLabel setNeedsLayout:YES];
        
        return inputLabel;
    }
    
    
    CAMultiAudioMatrixCell *cellView = [self.matrixTable makeViewWithIdentifier:@"MatrixMixerCell" owner:self];
    NSSlider *slider = cellView.volumeSlider;
    
    slider.tag = ((row+1)*100) + columnIndex-1;
    
    Float32 volume = [self.downMixer getVolumeforChannel:(UInt32)row outChannel:(UInt32)columnIndex-1];
    slider.doubleValue = volume;
    
    
    return cellView;
}

-(void)windowWillClose:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(mixerWindowWillClose:)])
    {
    
        [self.delegate mixerWindowWillClose:self];
    }
}


- (void)windowDidLoad {

    [super windowDidLoad];
    NSNib *cellNib = [[NSNib alloc] initWithNibNamed:@"CAMultiAudioMatrixView" bundle:nil];
    self.matrixTable.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    

    self.matrixTable.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    
    [self.matrixTable registerNib:cellNib forIdentifier:@"MatrixMixerCell"];
    
    if (self.matrixTable.numberOfColumns < self.downMixer.outputChannelCount)
    {
        for (int i = 0; i < self.downMixer.outputChannelCount; i++)
        {
            NSTableColumn *newCol = [[NSTableColumn alloc] init];
            [newCol.headerCell setStringValue:[NSString stringWithFormat:@"Output %d",i]];
            
            newCol.resizingMask = NSTableColumnAutoresizingMask;
            
            [self.matrixTable addTableColumn:newCol];
        }
    }
    
    [self.matrixTable sizeToFit];
    [self.matrixTable reloadData];
    self.effectsController.audioNode = self.audioNode;
    
}
@end
