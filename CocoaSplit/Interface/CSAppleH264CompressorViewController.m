//
//  CSAppleH264CompressorViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/28/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSAppleH264CompressorViewController.h"

@interface CSAppleH264CompressorViewController ()

@end

@implementation CSAppleH264CompressorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


-(instancetype)init
{
    return [self initWithNibName:@"CSAppleH264CompressorViewController" bundle:nil];
}

-(void)loadView
{
    [super loadView];
    self.profiles = @[[NSNull null], @"Baseline", @"Main", @"High"];

}


@end
