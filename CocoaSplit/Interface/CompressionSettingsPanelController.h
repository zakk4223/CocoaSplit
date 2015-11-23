//
//  CompressionSettingsPanelController.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "h264Compressor.h"

@interface CompressionSettingsPanelController : NSWindowController

@property (strong) IBOutlet NSObjectController *compressorObjectController;

@property (strong) id <h264Compressor> compressor;
@property (strong) NSArray *compressorTypes;
@property (strong) NSString *selectedCompressorType;
@property (strong) NSString *saveProfileName;
@property (strong) IBOutlet NSObjectController *baseObjectController;

-(void)saveCompressPanel;
-(void)deleteCompressPanel;
-(void)closeCompressPanel;
- (IBAction)saveCompressPanel:(id)sender;



@end
