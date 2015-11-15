//
//  CSNewOutputWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSNewOutputWindowController.h"
#import "CSPluginLoader.h"


@implementation CSNewOutputWindowController

@synthesize selectedOutputType = _selectedOutputType;


-(instancetype) init
{
    if (self = [self initWithWindowNibName:@"CSNewOutputWindowController"])
    {
        NSMutableDictionary *servicePlugins = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];
        
        self.outputTypes = servicePlugins.allKeys;
        NSLog(@"OUTPUT TYPES %@", self.outputTypes);
    }
    
    return self;
}


-(NSString *)selectedOutputType
{
    return _selectedOutputType;
}


-(void)setSelectedOutputType:(NSString *)selectedOutputType
{
    _selectedOutputType = selectedOutputType;
    NSMutableDictionary *servicePlugins = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];
    Class serviceClass = servicePlugins[_selectedOutputType];
    
    
    NSObject<CSStreamServiceProtocol>*serviceObj;
    
    if (serviceClass)
    {
        serviceObj = [[serviceClass alloc] init];
    }
    
    if (serviceObj)
    {
        if (self.pluginViewController)
        {
            [self.pluginViewController.view removeFromSuperview];
        }
        self.streamServiceObject = serviceObj;
        NSViewController *serviceConfigView = [self.streamServiceObject getConfigurationView];
        [self.serviceConfigView addSubview:serviceConfigView.view];
        self.pluginViewController = serviceConfigView;
    }
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)addButtonAction:(id)sender
{
    [self.pluginViewController commitEditing];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}


@end
