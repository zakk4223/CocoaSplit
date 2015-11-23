//
//  CompressionSettingsPanelController.m
//  CocoaSplit
//
//  Created by Zakk on 11/22/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CompressionSettingsPanelController.h"

@interface CompressionSettingsPanelController ()

@end

@implementation CompressionSettingsPanelController

-(instancetype) init
{
    if (self = [self initWithWindowNibName:@"CompressionSettingsPanel"])
    {
        self.compressorTypes = @[@"x264", @"AppleVTCompressor", @"None"];
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(void)saveCompressPanel
{
    [self.compressorObjectController commitEditing];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];

}

-(void)deleteCompressPanel
{
    
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseStop];
}

-(void)closeCompressPanel
{
    [self.compressorObjectController discardEditing];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)saveCompressPanel:(id)sender
{
    [self.compressorObjectController commitEditing];
    [self.baseObjectController commitEditing];
    [self.window.sheetParent endSheet:self.window returnCode:4242];

}


@end
