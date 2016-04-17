//
//  CSCompressorViewControllerProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 3/28/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@protocol CSCompressorViewControllerProtocol <NSObject>

@property (strong) NSObjectController *compressorController;
@property (strong) id compressor;


@end
