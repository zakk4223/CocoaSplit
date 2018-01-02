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



-(void)windowWillClose:(NSNotification *)notification
{
    NSWindow *closingWindow = [notification object];
}





@end
