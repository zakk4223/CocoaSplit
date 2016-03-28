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
        self.compressorTypes = @[@"x264", @"AppleVTCompressor", @"AppleProResCompressor", @"None"];
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupCompressorView];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(void)setupCompressorView
{
    
    if (!self.compressorSettingsView)
    {
        return;
    }
    
    
    if (!self.compressor)
    {
        if (self.compressorViewController)
        {
            [self.compressorViewController.view removeFromSuperview];
            self.compressorViewController = nil;
        }
    } else {
        id<CSCompressorViewControllerProtocol> compressorConfigView = [self.compressor getConfigurationView];
        if (compressorConfigView)
        {
            compressorConfigView.compressorController = self.compressorObjectController;
            
            [self.compressorSettingsView addSubview:((NSViewController *)compressorConfigView).view];
        
            [((NSViewController *)compressorConfigView).view setFrameOrigin:NSMakePoint(0, self.compressorSettingsView.frame.size.height - ((NSViewController *)compressorConfigView).view.frame.size.height)];
            self.compressorViewController = (NSViewController *)compressorConfigView;
        }
    }
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
