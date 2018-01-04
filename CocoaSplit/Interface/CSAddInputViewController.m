//
//  CSAddInputViewController.m
//  CocoaSplit
//
//  Created by Zakk on 5/8/16.
//

#import "CSAddInputViewController.h"
#import "NSView+NSLayoutConstraintFilter.h"
#import "CSCaptureSourceProtocol.h"
#import "CSPluginServices.h"
#import "AppDelegate.h"
#import "PreviewView.h"
#import "CSScriptInputSource.h"
#import "CSAudioInputSource.h"


@interface CSAddInputViewController ()

@end

@implementation CSAddInputViewController

@synthesize popover = _popover;

-(instancetype)init
{
    return [self initWithNibName:@"CSAddInputViewController" bundle:nil];
}

-(void)loadView
{
    
    [super loadView];
    [self adjustTableHeight:self.contentTable];
}


-(NSPopover *)popover
{
    return _popover;
}

-(void)setPopover:(NSPopover *)popover
{
    [self willChangeValueForKey:@"sourceTypes"];
    _sourceTypeList = nil;
    [self didChangeValueForKey:@"sourceTypes"];

    _popover = popover;
    _popover.delegate = self;
}


-(void)popoverWillClose:(NSNotification *)notification
{
    [self willChangeValueForKey:@"sourceTypes"];
    _sourceTypeList = @[];
    [self didChangeValueForKey:@"sourceTypes"];
    self.selectedInput = nil;
    
}


/*
- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    return nil;
}
*/


-(NSInteger)adjustTableHeight:(NSTableView *)table
{
    NSInteger height = 0;
    for (int i = 0; i < table.numberOfRows; i++)
    {
        NSView *view = [table viewAtColumn:0 row:i makeIfNecessary:YES];

        height += view.frame.size.height;
        height += table.intercellSpacing.height;
        
    }
    


    NSRect vRect = table.frame;
    NSRect lRect = [table rectOfRow:self.contentTable.numberOfRows - 1];

    NSSize newSize = NSMakeSize(vRect.size.width+2, NSMaxY(lRect)+(lRect.size.height/2));
    
    vRect.size = newSize;
    vRect.origin.y = self.view.frame.size.height/2 - newSize.height/2;

    
    self.popover.contentSize = newSize;
    return height;
}


-(void)deviceClicked
{
    if (self.contentTable.clickedRow == 0)
    {
        self.parentSourceType = nil;
        [self.contentTable reloadData];
        [self adjustTableHeight:self.contentTable];
        return;
    } else {
        NSArray *devices = [self.parentSourceType valueForKey:@"availableVideoDevices"];
        CSAbstractCaptureDevice *clickedDev = [devices objectAtIndex:self.contentTable.clickedRow-1];
        if (clickedDev)
        {
            NSString *selectedType = [self.parentSourceType valueForKey:@"instanceLabel"];

            if ([selectedType isEqualToString:@"Audio"])
            {
            
                CSAudioInputSource *audioSrc = [[CSAudioInputSource alloc] initWithAudioNode:(CAMultiAudioNode *)clickedDev.captureDevice];
                [self addInput:audioSrc];
            } else {
            InputSource *newSrc =  [[InputSource alloc] init];
            newSrc.selectedVideoType = selectedType;
            newSrc.videoInput.activeVideoDevice = clickedDev;
            [self addInput:newSrc];
            [newSrc autoCenter];
            }
            return;
        }
        
    }
    
}
- (IBAction)initalTableButtonClicked:(id)sender
{
    
    
    if (self.parentSourceType)
    {
        [self deviceClicked];
    } else {
        
        NSObject *clickedItem = [ _sourceTypeList objectAtIndex:self.contentTable.clickedRow];
        if ([[clickedItem valueForKey:@"instanceLabel"] isEqualToString:@"Script"])
        {
            CSScriptInputSource *newScript = [[CSScriptInputSource alloc] init];
            [self addInput:newScript];
            [self.previewView openInputConfigWindow:newScript.uuid];
            return;
        }
        
        NSObject <CSCaptureSourceProtocol> *clickedCapture = (NSObject <CSCaptureSourceProtocol> *)clickedItem;
        
        
        NSArray *availableDevices = [clickedCapture valueForKey:@"availableVideoDevices"];
        
        if (availableDevices.count > 0)
        {
            self.parentSourceType = clickedCapture;
            
            [self.contentTable reloadData];
            
            [self adjustTableHeight:self.contentTable];
            
        } else {
            InputSource *newSrc = [[InputSource alloc] init];
            newSrc.selectedVideoType = clickedCapture.instanceLabel;
            newSrc.depth = -FLT_MAX;
            [self addInput:newSrc];
            [self.previewView openInputConfigWindow:newSrc.uuid];
            
        }
    }
    [self.contentTable deselectAll:nil];
}

- (IBAction)inputTableButtonClicked:(id)sender
{
    CSAbstractCaptureDevice *clickedDevice;
    clickedDevice = [self.selectedInput.availableVideoDevices objectAtIndex:[self.deviceTable rowForView:sender]];
    if (clickedDevice)
    {
        InputSource *newSrc =  [[InputSource alloc] init];
        newSrc.selectedVideoType = self.selectedInput.instanceLabel;
        newSrc.videoInput.activeVideoDevice = clickedDevice;
        newSrc.depth = -FLT_MAX;
        [self addInput:newSrc];
        [newSrc autoCenter];
        
    }
    
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (self.parentSourceType)
    {
        if (row == 0)
        {
            return nil;
        }
        NSArray *devices = [self.parentSourceType valueForKey:@"availableVideoDevices"];
        return [devices objectAtIndex:row-1];
    }
    
    return [_sourceTypeList objectAtIndex:row];
}


-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (self.parentSourceType)
    {
        NSArray *devices = [self.parentSourceType valueForKey:@"availableVideoDevices"];
        return devices.count+1;
    } else {
        if (!_sourceTypeList)
        {
            [self makeSourceTypes];
        }
        return _sourceTypeList.count;
    }
    
    return 0;
}


-(void)addInput:(NSObject<CSInputSourceProtocol> *)toAdd
{
    
    
    if (self.previewView)
    {
        [self.previewView addInputSourceWithInput:toAdd];
    }
 
  }

/*
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

*/

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (self.parentSourceType)
    {
        if (row == 0)
        {
            return [tableView makeViewWithIdentifier:@"goBackView" owner:self];
        }
        return [tableView makeViewWithIdentifier:@"deviceView" owner:self];
    }
    
    NSObject <CSCaptureSourceProtocol> *item = [_sourceTypeList objectAtIndex:row];
    if ([item isEqualTo:[NSNull null]])
    {
        return [tableView makeViewWithIdentifier:@"initialInputViewScript" owner:self];
    }
    
    NSArray *availableVideoDevices = [item valueForKey:@"availableVideoDevices"];
    if (availableVideoDevices && availableVideoDevices.count > 0)
    {
        return [tableView makeViewWithIdentifier:@"arrowView" owner:self];
    } else {
        return [tableView makeViewWithIdentifier:@"defaultView" owner:self];
    }

    return nil;
}


-(void)makeSourceTypes
{
    if (!_sourceTypeList)
    {
        NSMutableDictionary *pluginMap = [[CSPluginLoader sharedPluginLoader] sourcePlugins];
        
        NSArray *sortedKeys = [pluginMap.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        
        NSMutableArray *ret = [[NSMutableArray alloc] init];
        for (NSString *key in sortedKeys)
        {
            Class captureClass = pluginMap[key];
            NSObject <CSCaptureSourceProtocol> *newCaptureSession;
            
            newCaptureSession = [[captureClass alloc] init];
            
            [ret addObject:newCaptureSession];
        }
        
        NSImage *scriptImage = [NSImage imageNamed:@"NSScriptTemplate"];
        scriptImage.template = NO;
        
        [ret addObject:@{@"libraryImage": scriptImage, @"instanceLabel": @"Script", @"availableVideoDevices": @[]}];
        
        NSMutableDictionary *audioDict = [NSMutableDictionary dictionary];

        NSMutableArray *audioInputs = [NSMutableArray array];
        
        for(CAMultiAudioNode *input in [CaptureController sharedCaptureController].multiAudioEngine.audioInputs)
        {
            CSAbstractCaptureDevice *newDev = [[CSAbstractCaptureDevice alloc] initWithName:input.name device:input uniqueID:input.nodeUID];
            [audioInputs addObject:newDev];
        }
        audioDict[@"availableVideoDevices"] = audioInputs;
        audioDict[@"instanceLabel"] = @"Audio";
        NSImage *audioImage = [NSImage imageNamed:@"NSAudioOutputVolumeMedTemplate"];
        audioImage.template = NO;
        
        audioDict[@"libraryImage"] = audioImage;
        
        [ret addObject:audioDict];
        //[ret addObject:[NSNull null]];
        
        _sourceTypeList = ret;
        
    }
    
    self.contentData = _sourceTypeList;

}


@end
