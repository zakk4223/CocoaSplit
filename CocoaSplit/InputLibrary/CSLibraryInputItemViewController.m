//
//  CSLibraryInputItemViewController.m
//  CocoaSplit
//
//  Created by Zakk on 10/19/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLibraryInputItemViewController.h"
#import "CaptureController.h"

@interface CSLibraryInputItemViewController ()

@end

@implementation CSLibraryInputItemViewController

-(instancetype) init
{
    if (self = [super initWithNibName:@"CSInputLibraryItemView" bundle:nil])
    {
        
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)addButtonClicked:(id)sender {
    
    InputSource *iSrc = [self.item makeInput];
    if (self.item.autoFit)
    {
        iSrc.autoPlaceOnFrameUpdate = YES;
    }
    SourceLayout *useLayout = [CaptureController sharedCaptureController].activeLayout;
    
    if ([NSEvent modifierFlags]& NSCommandKeyMask)
    {
        useLayout = [CaptureController sharedCaptureController].selectedLayout;
    }
    [useLayout addSource:iSrc];
    
    
}
@end
