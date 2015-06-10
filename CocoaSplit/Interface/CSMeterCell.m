//
//  CSMeterCell.m
//  CocoaSplit
//
//  Created by Zakk on 11/17/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSMeterCell.h"

@implementation CSMeterCell


-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setupView];
}


-(void)prepareForInterfaceBuilder
{
 
    [super prepareForInterfaceBuilder];
    [self setupView];
}


-(void)setupView
{
    
    [self setFrameCenterRotation:90];
}


@end
