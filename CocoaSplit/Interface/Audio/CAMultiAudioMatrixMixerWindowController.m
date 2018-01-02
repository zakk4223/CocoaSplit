//
//  CAMultiAudioMatrixMixerWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 6/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioMatrixCell.h"
#import "CAMultiAudioUnit.h"

@interface CAMultiAudioMatrixMixerWindowController ()

@end

@implementation CAMultiAudioMatrixMixerWindowController


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








-(void)windowWillClose:(NSNotification *)notification
{
    
    NSWindow *closingWindow = [notification object];
    
    if (!closingWindow)
    {
        return;
    }
    
    if (self.eqWindow == closingWindow)
    {
        self.eqWindow = nil;
    } else if (self.compressorWindow == closingWindow) {
        self.compressorWindow = nil;
    }
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
