//
//  CSAppleH264CompressorViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/28/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppleVTCompressor.h"
#import "CSCompressorViewControllerProtocol.h"

@interface CSAppleH264CompressorViewController : NSViewController <CSCompressorViewControllerProtocol>

@property (strong) AppleVTCompressor *compressor;
@property (strong) NSObjectController *compressorController;
@property (strong) NSArray *profiles;

@end
