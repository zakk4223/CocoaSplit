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
        _outputDestination = [[OutputDestination alloc] init];
        self.buttonLabel = @"Add";
    }
    
    return self;
}


-(void)setOutputDestination:(OutputDestination *)outputDestination
{
    _outputDestination = outputDestination;
    self.buttonLabel = @"Save";
    if (outputDestination.streamServiceObject)
    {
        self.streamServiceObject = outputDestination.streamServiceObject;
        Class serviceClass = self.streamServiceObject.class;
        self.selectedOutputType = [serviceClass label];
    }
    
    if (self.outputDestination.compressor_name)
    {
        id<VideoCompressor> oCompressor = self.compressors[self.outputDestination.compressor_name];
        if (!oCompressor)
        {
            self.outputDestination.compressor_name = nil;
        }
    }
}


-(OutputDestination *)outputDestination
{
    return _outputDestination;
}


-(void)setupServiceView
{
    
    if (!self.serviceConfigView)
    {
        return;
    }
    
    
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupServiceView];

        
    });
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self.outputObjectController discardEditing];
    [self.pluginViewController discardEditing];
    
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)addButtonAction:(id)sender
{
    [self.outputObjectController commitEditing];
    [self.pluginViewController commitEditing];
    self.outputDestination.streamServiceObject = self.streamServiceObject;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)openCompressorEdit:(id)sender
{

    NSObject <VideoCompressor>*editCompressor;
    
    if (!self.outputDestination.compressor_name)
    {
        return;
    }
    
    editCompressor = self.compressors[self.outputDestination.compressor_name];
    
    if (!editCompressor)
    {
        return;
    }
    
    
    self.compressionPanelController = [[CompressionSettingsPanelController alloc] init];
    
    if (editCompressor.active)
    {
        self.compressionPanelController.compressor = editCompressor;
    } else {
        self.compressionPanelController.compressor = editCompressor.copy;
    }
    

    [self.window beginSheet:self.compressionPanelController.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSModalResponseStop:
                if (self.compressionPanelController.compressor.active)
                {
                    return;
                }
                [self willChangeValueForKey:@"compressors"];
                [self.compressors removeObjectForKey:self.compressionPanelController.compressor.name];
                [self didChangeValueForKey:@"compressors"];
                [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorDeleted object:self.compressionPanelController.compressor userInfo:nil];

                break;
            case NSModalResponseOK:
            {
                
                
                if (!self.compressionPanelController.compressor.active)
                {
                    if (![editCompressor.name isEqualToString:self.compressionPanelController.compressor.name])
                    {
                        [self.compressors removeObjectForKey:editCompressor.name];
                        NSDictionary *notifyMsg = [NSDictionary dictionaryWithObjectsAndKeys:editCompressor.name, @"oldName", self.compressionPanelController.compressor, @"compressor", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorRenamed object:notifyMsg];
                        
                    }
                    self.compressors[self.compressionPanelController.compressor.name] = self.compressionPanelController.compressor;
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorReconfigured object:self.compressionPanelController.compressor];
                
                break;
            }
            case 4242:
                if (self.compressionPanelController.saveProfileName)
                {
                    self.compressionPanelController.compressor.name = self.compressionPanelController.saveProfileName.mutableCopy;
                    [self willChangeValueForKey:@"compressors"];
                    self.compressors[self.compressionPanelController.compressor.name] = self.compressionPanelController.compressor;
                    [self didChangeValueForKey:@"compressors"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorAdded object:self.compressionPanelController.compressor userInfo:nil];

                }
            default:
                break;
        }
    }];
}


@end
