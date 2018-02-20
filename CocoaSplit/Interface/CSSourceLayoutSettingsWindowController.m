//
//  CSSourceLayoutSettingsWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 2/17/18.
//

#import "CSSourceLayoutSettingsWindowController.h"

@interface CSSourceLayoutSettingsWindowController ()

@end

@implementation CSSourceLayoutSettingsWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(instancetype)init
{
    if (self = [self initWithWindowNibName:@"CSSourceLayoutSettingsWindowController"])
    {

    }
    
    return self;
}
-(void)awakeFromNib
{
    self.window.title = [NSString stringWithFormat:@"%@ Settings", self.layout.name];
    
    self.filterListViewController.baseLayer = self.layout.rootLayer;
    self.filterListViewController.filterArrayName = @"backgroundFilters";
}

- (IBAction)clearGradient:(id)sender
{
    [self.layout clearGradient];
    
}
@end
