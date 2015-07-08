//
//  MovieCaptureViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "MovieCaptureViewController.h"

@interface MovieCaptureViewController ()

@end

@implementation MovieCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.repeatTypeMap = @{@"None": @(kCSMovieRepeatNone),
                                @"One": @(kCSMovieRepeatOne),
                                @"All": @(kCSMovieRepeatAll)
                                };
        
        self.repeatSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]];
    }
    return self;
}

@end
