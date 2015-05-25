//
//  CSMidiManagerWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 5/16/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSMidiManagerWindowController.h"
#import "CaptureController.h"


@interface CSMidiManagerWindowController ()

@end

@implementation CSMidiManagerWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    NSMutableArray *identList = [NSMutableArray array];
    
    for (id <MIKMIDIMappableResponder> responder in self.responderList)
    {
        NSArray *idents = [responder commandIdentifiers];
        for (NSString *ident in idents)
        {
            [identList addObject:@{@"command":ident, @"responder":responder, @"display":[NSString stringWithFormat:@"%@-%@", [responder MIDIIdentifier], ident]}];
        }
    }
    
    self.commandIdentfiers = identList;
    
    
    
}


-(void)createModal
{
    NSWindow *newWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, self.window.frame.size.width, 300) styleMask:NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    NSTextField *text = [[NSTextField alloc] initWithFrame:newWindow.frame];
    text.editable = NO;
    text.selectable = NO;
    text.drawsBackground = NO;
    text.bordered = NO;
    text.stringValue = @"Activate the MIDI control for this input";
    [text sizeToFit];

    NSRect wFrame = self.window.frame;
    NSRect tFrame = text.frame;
    
    
    [text setFrameOrigin:NSMakePoint(wFrame.size.width/2 - tFrame.size.width/2, wFrame.size.height/2 - tFrame.size.height/2)];
    
    
    [newWindow.contentView addSubview:text];
    
    self.modalWindow = newWindow;
    [self.window beginSheet:newWindow completionHandler:nil];
}


-(void)learnedDone
{

    if (self.modalWindow)
    {
        [self.window endSheet:self.modalWindow];
        self.modalWindow = nil;
    }
}




- (IBAction)learnPushed:(id)sender {
    NSTableView *bTable = (NSTableView *)sender;
    NSInteger clickedRow = [bTable clickedRow];
    
    
    NSDictionary *commandMap = [self.commandIdentfiers objectAtIndex:clickedRow];
    
    
    [self createModal];
    [self.captureController learnMidiForCommand:commandMap[@"command"] withRepsonder:commandMap[@"responder"]];
    
    
}
@end
