//
//  CompressionSettingsPanelController.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VideoCompressor.h"
#import "CSCompressorViewControllerProtocol.h"


@interface CompressionSettingsPanelController : NSWindowController
@property (weak) IBOutlet NSView *compressorSettingsView;
@property (strong) NSViewController *compressorViewController;


@property (strong) IBOutlet NSObjectController *compressorObjectController;

@property (strong) id <VideoCompressor> compressor;
@property (strong) NSArray *compressorTypes;
@property (strong) NSString *selectedCompressorType;
@property (strong) NSString *saveProfileName;
@property (strong) IBOutlet NSObjectController *baseObjectController;

-(void)saveCompressPanel;
-(void)deleteCompressPanel;
-(void)closeCompressPanel;
- (IBAction)saveCompressPanel:(id)sender;



@end
