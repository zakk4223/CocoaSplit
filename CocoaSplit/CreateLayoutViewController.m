//
//  CreateLayoutViewController.m
//  CocoaSplit
//
//  Created by Zakk on 9/9/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CreateLayoutViewController.h"

@interface CreateLayoutViewController ()

@end

@implementation CreateLayoutViewController


-(instancetype) init
{
    return [self initWithNibName:@"CreateLayoutViewController" bundle:nil];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (IBAction)layoutNameEntered:(NSTextField *)sender
{
    
    if (self.textFieldDelegate)
    {
        [self.textFieldDelegate setValue:sender.stringValue forKey:@"layoutTextValue"];
    }
}
@end
