//
//  CAMultiAudioMatrixMixerWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 6/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioMatrixCell.h"

@interface CAMultiAudioMatrixMixerWindowController ()

@end

@implementation CAMultiAudioMatrixMixerWindowController


- (IBAction)matrixVolumeChanged:(NSSlider *)sender
{
    UInt32 inputChannel = (UInt32)((sender.tag / 100) - 1 );
    UInt32 outputChannel = sender.tag % 100;
    
    [self.audioNode setVolume:[sender doubleValue] forChannel:inputChannel outChannel:outputChannel];
}


-(instancetype)initWithAudioMixer:(CAMultiAudioDownmixer *)node
{
    if (self = [self initWithWindowNibName:@"CAMultiAudioMatrixMixerWindowController"])
    {
        self.audioNode = node;
        //NSView *audioView = [node audioUnitNSView];
       // NSLog(@"AUDIO VIEW SIZE %@", NSStringFromRect(audioView.frame));
        //self.window.contentView = audioView;
        
    }
    
    return self;
}


-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    
    return self.audioNode.inputChannelCount;
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
    
    Float32 volume = [self.audioNode getVolumeforChannel:(UInt32)row outChannel:(UInt32)columnIndex-1];
    slider.doubleValue = volume;
    
    
    return cellView;
}


- (void)windowDidLoad {

    [super windowDidLoad];
    NSNib *cellNib = [[NSNib alloc] initWithNibNamed:@"CAMultiAudioMatrixView" bundle:nil];
    self.matrixTable.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    

    self.matrixTable.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    
    [self.matrixTable registerNib:cellNib forIdentifier:@"MatrixMixerCell"];
    
    if (self.matrixTable.numberOfColumns < self.audioNode.outputChannelCount)
    {
        for (int i = 0; i < self.audioNode.outputChannelCount; i++)
        {
            NSTableColumn *newCol = [[NSTableColumn alloc] init];
            [newCol.headerCell setStringValue:[NSString stringWithFormat:@"Output %d",i]];
            
            newCol.resizingMask = NSTableColumnAutoresizingMask;
            
            [self.matrixTable addTableColumn:newCol];
        }
    }
    
    [self.matrixTable sizeToFit];
    [self.matrixTable reloadData];
    
}
@end
