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
    
    [self buildIdentifiers];
    
    
}

-(void)buildIdentifiers
{
    NSMutableArray *identList = [NSMutableArray array];
    
    
    for (id <MIKMIDIMappableResponder> responder in self.responderList)
    {
        NSString *responderName;
        
        if ([responder respondsToSelector:@selector(MIDIShortIdentifier)])
        {
            responderName = [responder MIDIShortIdentifier];
        } else {
            responderName = [responder MIDIIdentifier];
        }
        
        
        NSArray *idents = [responder commandIdentifiers];
        for (NSString *ident in idents)
        {
            NSMutableSet *midiMappings = [NSMutableSet set];
            
            NSSet *allMaps = [MIKMIDIMappingManager sharedManager].mappings;
            
            for (MIKMIDIMapping *cMap in allMaps)
            {
                NSSet *commandMaps = [cMap mappingItemsForCommandIdentifier:ident responder:responder];
                if (commandMaps)
                {
                    [midiMappings unionSet:commandMaps];
                }
            }
            [identList addObject:@{@"command":ident, @"responder":responder, @"count":@(midiMappings.count), @"display":[NSString stringWithFormat:@"%@-%@", responderName, ident]}];
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
    
    NSButton *cancel = [[NSButton alloc] initWithFrame:newWindow.frame];
    cancel.title = @"Cancel";
    [cancel setButtonType:NSMomentaryLightButton];
    [cancel setBezelStyle:NSRoundedBezelStyle];
    [cancel setAction:@selector(learnCancelled:)];
    [cancel setTarget:self];
    
    
    [cancel sizeToFit];

    NSRect wFrame = self.window.frame;
    NSRect tFrame = text.frame;
    NSRect cFrame = cancel.frame;
    
    [text setFrameOrigin:NSMakePoint(wFrame.size.width/2 - tFrame.size.width/2, wFrame.size.height/2 - tFrame.size.height/2)];
    
    [cancel setFrameOrigin:NSMakePoint(wFrame.size.width/2 - cFrame.size.width/2, wFrame.size.height/2 - cFrame.size.height/2 - tFrame.size.height*2)];
    self.modalWindow = newWindow;
    [self.window beginSheet:newWindow completionHandler:nil];

    [newWindow.contentView addSubview:text];
    [newWindow.contentView addSubview:cancel];

}


-(IBAction)learnCancelled:(id)sender
{
    if (self.modalWindow)
    {
        [self.window endSheet:self.modalWindow];
        self.modalWindow = nil;
    }
}


-(void)learnedDone
{

    if (self.modalWindow)
    {
        [self.window endSheet:self.modalWindow];
        self.modalWindow = nil;
    }
    [self buildIdentifiers];
}




-(IBAction)clearPushed:(id)sender
{
    NSTableView *bTable = (NSTableView *)sender;
    NSInteger clickedRow = [bTable clickedRow];
    
    
    NSDictionary *commandMap = [self.commandIdentfiers objectAtIndex:clickedRow];
    
    
    [self.captureController clearLearnedMidiForCommand:commandMap[@"command"] withResponder:commandMap[@"responder"]];

    [self buildIdentifiers];
}


- (IBAction)learnPushed:(id)sender {
    NSTableView *bTable = (NSTableView *)sender;
    NSInteger clickedRow = [bTable clickedRow];
    
    
    NSDictionary *commandMap = [self.commandIdentfiers objectAtIndex:clickedRow];
    
    
    [self createModal];
    [self.captureController learnMidiForCommand:commandMap[@"command"] withRepsonder:commandMap[@"responder"]];
    
    
}
@end
