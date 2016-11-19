//
//  CSInstantRecorderCompressorViewController.h
//  CocoaSplit
//
//  Created by Zakk on 4/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSCompressorViewControllerProtocol.h"
#import "CSIRCompressor.h"


@interface CSInstantRecorderCompressorViewController : NSViewController <CSCompressorViewControllerProtocol>
@property (strong) CSIRCompressor *compressor;
@property (strong) NSObjectController *compressorController;
@property (strong) NSString *encoderName;


- (IBAction)selectCompressorType:(id)sender;

@end


