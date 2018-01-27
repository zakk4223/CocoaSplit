//
//  CSPassthroughCompressorViewController.h
//  CocoaSplit
//
//  Created by Zakk on 1/27/18.
//

#import <Cocoa/Cocoa.h>
#import "CSCompressorViewControllerProtocol.h"
#import "CSPassthroughCompressor.h"

@interface CSPassthroughCompressorViewController : NSViewController <CSCompressorViewControllerProtocol>

@property (strong) CSPassthroughCompressor *compressor;

@property (strong) NSObjectController *compressorController;

@end
