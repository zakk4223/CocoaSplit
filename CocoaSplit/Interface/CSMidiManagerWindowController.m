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


- (IBAction)learnPushed:(id)sender {
    NSTableView *bTable = (NSTableView *)sender;
    NSInteger clickedRow = [bTable clickedRow];
    
    
    NSDictionary *commandMap = [self.commandIdentfiers objectAtIndex:clickedRow];
    
    //NSLog(@"WILL LEARN %@", command);
    
    [self.captureController learnMidiForCommand:commandMap[@"command"] withRepsonder:commandMap[@"responder"]];
    
    
}
@end
