//
//  CSInstantRecorderCompressorViewController.m
//  CocoaSplit
//
//  Created by Zakk on 4/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSInstantRecorderCompressorViewController.h"

@interface CSInstantRecorderCompressorViewController ()

@end

@implementation CSInstantRecorderCompressorViewController


-(instancetype)init
{
    return [self initWithNibName:@"CSInstantRecorderCompressorViewController" bundle:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do view setup here.
}

- (IBAction)selectCompressorType:(NSButton *)sender {
    
    CSIRCompressor *tcomp = self.compressor;
    tcomp.usex264 = NO;
    tcomp.useAppleH264 = NO;
    tcomp.useAppleProRes = NO;
    tcomp.useNone = NO;

    switch (sender.tag)
    {
        case 0:
            //useNone
            tcomp.useNone = YES;
            break;
        case 1:
            tcomp.useAppleH264 = YES;
            break;
        case 2:
            tcomp.useAppleProRes = YES;
            break;
        case 3:
            tcomp.usex264 = YES;
            break;
        default:
            break;
    }
}
@end
