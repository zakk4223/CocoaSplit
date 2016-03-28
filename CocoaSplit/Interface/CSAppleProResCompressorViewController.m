//
//  CSAppleProResCompressorViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/28/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSAppleProResCompressorViewController.h"

@interface CSAppleProResCompressorViewController ()

@end

@implementation CSAppleProResCompressorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.compressorTypes = @{@"ProRes 4444": @(kCMVideoCodecType_AppleProRes4444),
                             @"ProRes 422":  @(kCMVideoCodecType_AppleProRes422),
                             @"ProRes 422HQ": @(kCMVideoCodecType_AppleProRes422HQ),
                             @"ProRes 422LT": @(kCMVideoCodecType_AppleProRes422LT),
                             @"ProRes 422Proxy": @(kCMVideoCodecType_AppleProRes422Proxy),
                             };
}




@end
