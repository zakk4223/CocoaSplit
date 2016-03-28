//
//  CSAppleProResCompressorViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/28/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppleProResCompressor.h"
#import "CSCompressorViewControllerProtocol.h"

@interface CSAppleProResCompressorViewController : NSViewController <CSCompressorViewControllerProtocol>

@property (strong) NSObjectController *compressorController;

@property (strong) NSDictionary *compressorTypes;

@end
