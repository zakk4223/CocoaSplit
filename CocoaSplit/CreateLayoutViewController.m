//
//  CreateLayoutViewController.m
//  CocoaSplit
//
//  Created by Zakk on 9/9/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CreateLayoutViewController.h"
#import "CaptureController.h"
#import "AppDelegate.h"

@interface CreateLayoutViewController ()

@end

@implementation CreateLayoutViewController
@synthesize sourceLayout = _sourceLayout;


-(instancetype) init
{
    return [self initWithNibName:@"CreateLayoutViewController" bundle:nil];
}


-(instancetype) initForBuiltin
{
    return [self initWithNibName:@"EditBuiltinLayoutView" bundle:nil];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _createDialog = NO;
        
        // Initialization code here.
    }
    return self;
}

- (IBAction)createButtonClicked:(id)sender
{
    
    
    [self commitEditing];
    
    if (self.sourceLayout)
    {
        [self.sourceLayout updateCanvasWidth:self.canvas_width height:self.canvas_height];
    }
    
    
    if (self.sourceLayout && self.createDialog)
    {
        AppDelegate *appDel = NSApp.delegate;
        
        CaptureController *controller = appDel.captureController;
        
        [controller addLayoutFromBase:self.sourceLayout];
    }
    [self.popover close];
    
    
}

-(void)popoverDidClose:(NSNotification *)notification
{
    
    AppDelegate *appDel = NSApp.delegate;
    

    self.popover.contentViewController = nil;
}


-(SourceLayout *)sourceLayout
{
    return _sourceLayout;
}


-(void) setSourceLayout:(SourceLayout *)sourceLayout
{
    _sourceLayout = sourceLayout;
    if (_sourceLayout)
    {
        self.canvas_width = sourceLayout.canvas_width;
        self.canvas_height = sourceLayout.canvas_height;
    }
}


@end
