//
//  CSNewOutputWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSNewOutputWindowController.h"
#import "CSPluginLoader.h"
#import "OutputDestination.h"


@implementation CSNewOutputWindowController

@synthesize selectedOutputType = _selectedOutputType;
@synthesize outputDestination = _outputDestination;


-(instancetype) init
{
    if (self = [self initWithWindowNibName:@"CSNewOutputWindowController"])
    {
        NSMutableDictionary *servicePlugins = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];
        
        self.outputTypes = servicePlugins.allKeys;
        self.outputDestination = [[OutputDestination alloc] init];
    }
    
    return self;
}


-(void)setOutputDestination:(OutputDestination *)outputDestination
{
    _outputDestination = outputDestination;
    if (outputDestination.streamServiceObject)
    {
        self.streamServiceObject = outputDestination.streamServiceObject;
        Class serviceClass = self.streamServiceObject.class;
        self.selectedOutputType = [serviceClass label];
    }
}

-(OutputDestination *)outputDestination
{
    return _outputDestination;
}


-(void)setupServiceView
{
    if (!self.streamServiceObject)
    {
        if (self.pluginViewController)
        {
            [self.pluginViewController.view removeFromSuperview];
            self.pluginViewController = nil;
        }
    } else {
        NSViewController *serviceConfigView = [self.streamServiceObject getConfigurationView];
        [self.serviceConfigView addSubview:serviceConfigView.view];
        
        [serviceConfigView.view setFrameOrigin:NSMakePoint(0, self.serviceConfigView.frame.size.height - serviceConfigView.view.frame.size.height)];
        self.pluginViewController = serviceConfigView;
    }
}

-(NSString *)selectedOutputType
{
    return _selectedOutputType;
}



-(void)setSelectedOutputType:(NSString *)selectedOutputType
{
    
    _selectedOutputType = selectedOutputType;
    NSMutableDictionary *servicePlugins = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];
    Class serviceClass = servicePlugins[selectedOutputType];
    
    
    if (self.streamServiceObject && [self.streamServiceObject isKindOfClass:serviceClass])
    {
        [self setupServiceView];
        return;
    }
    
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
        self.pluginViewController = nil;
        
        self.outputDestination.type_name = [serviceObj.class label];
        self.streamServiceObject = serviceObj;
        [self setupServiceView];
    }
}


- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupServiceView];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)addButtonAction:(id)sender
{
    [self.pluginViewController commitEditing];
    NSString *destination = [self.streamServiceObject getServiceDestination];
    
    self.outputDestination.destination = destination;
    self.outputDestination.streamServiceObject = self.streamServiceObject;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}


@end
