//
//  CSx264CompressorViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/28/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "x264Compressor.h"
#import "CSCompressorViewControllerProtocol.h"

@interface CSx264CompressorViewController : NSViewController <CSCompressorViewControllerProtocol>


@property (strong) x264Compressor *compressor;
@property (strong) NSObjectController *compressorController;

@end
