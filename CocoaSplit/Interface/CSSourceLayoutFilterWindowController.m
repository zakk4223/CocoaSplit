//
//  CSSourceLayoutFilterWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 1/28/18.
//

#import "CSSourceLayoutFilterWindowController.h"
#import "CSFilterChooserWindowController.h"
#import "CSCIFilterConfigProxy.h"

@interface CSSourceLayoutFilterWindowController ()

@end

@implementation CSSourceLayoutFilterWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(instancetype)init
{
    if (self = [self initWithWindowNibName:@"CSSourceLayoutFilterWindowController"])
    {
        
    }

    return self;
}


- (IBAction)addFilterAction:(NSSegmentedControl *)sender
{
    NSString *filterName = [CSFilterChooserWindowController run];
    
    [self.layout addLayoutFilter:filterName];
}

- (IBAction)removeFilter:(NSSegmentedControl *)sender
{
    CIFilter *selectedFilter;
    selectedFilter = [self.layout.rootLayer.filters objectAtIndex:self.filterListTable.selectedRow];
    [self.layout deleteLayoutFilter:selectedFilter.name];
}


-(void)openUserFilterPanel:(CIFilter *)forFilter forLayer:(CALayer *)forLayer withType:(NSString *)withType
{
    if (!forFilter)
    {
        return;
    }
    
    CSCIFilterConfigProxy *filterProxy = [[CSCIFilterConfigProxy alloc] init];
    
    
    filterProxy.baseLayer = forLayer;
    filterProxy.layerFilterName = forFilter.name;
    filterProxy.filterType = withType;
    
    
    IKFilterUIView *filterView = [forFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    
    
    if (forLayer)
    {
        CSCIFilterConfigProxy *filterProxy = [[CSCIFilterConfigProxy alloc] init];
        filterProxy.baseLayer = forLayer;
        filterProxy.layerFilterName = forFilter.name;
        filterProxy.filterType = withType;
        
        [filterProxy rebindViewControls:filterView];
        
    }
    
    
    self.userFilterWindow = [[NSWindow alloc] init];
    
    self.userFilterWindow.delegate = self;
    [self.userFilterWindow setContentSize:filterView.bounds.size];
    [self.userFilterWindow.contentView addSubview:filterView];
    self.userFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.userFilterWindow setReleasedWhenClosed:NO];
    
    [self.userFilterWindow makeKeyAndOrderFront:self.userFilterWindow];
    
}
- (IBAction)configureFilter:(NSSegmentedControl *)sender
{
    
    CIFilter *selectedFilter;
    
    selectedFilter = [self.layout.rootLayer.filters objectAtIndex:self.filterListTable.selectedRow];
    if (selectedFilter)
    {
        [self openUserFilterPanel:selectedFilter forLayer:self.layout.rootLayer withType:@"filters"];
        
        
    }

}

-(void)windowWillClose:(NSNotification *)notification
{
    self.userFilterWindow = nil;
}



- (IBAction)filterControlAction:(NSSegmentedControl *)sender
{
    NSInteger segment = sender.selectedSegment;
    
    switch (segment)
    {
        case 0:
            [self addFilterAction:sender];
            break;
        case 1:
            [self removeFilter:sender];
            break;
        case 2:
            [self configureFilter:sender];
            break;
        default:
            break;
    }
}



@end
