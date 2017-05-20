//
//  CSStreamOutputWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 8/7/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSStreamOutputWindowController.h"
#import "CaptureController.h"


@interface CSStreamOutputWindowController ()

@end

@implementation CSStreamOutputWindowController


-(instancetype) init
{
    return [self initWithWindowNibName:@"CSStreamOutputWindowController"];
}



- (void)windowDidLoad {
    [super windowDidLoad];
    self.sourceLayouts = [CaptureController sharedCaptureController].sourceLayouts;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (IBAction)outputEditClicked:(id)sender
{
    //hax
    OutputDestination *toEdit = [self.controller.captureDestinations objectAtIndex:self.outputTableView.clickedRow];

    [self.controller outputEditClicked:toEdit];
}


- (IBAction)outputSegmentedAction:(NSButton *)sender
{
    NSUInteger clicked = sender.tag;
    
    switch (clicked)
    {
        case 0:
        {
            [self.controller openAddOutputPopover:sender sourceRect:sender.bounds];
            break;
        }
        case 1:
        {
            [self.selectedCaptureDestinations enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
                [self.controller removeObjectFromCaptureDestinationsAtIndex:idx];
            }];
            break;
        }
        default:
            break;
    }
}


@end
