//
//  CSLayerFiltersViewController.m
//  CocoaSplit
//
//  Created by Zakk on 1/28/18.
//

#import "CSLayerFiltersViewController.h"
#import "CSFilterChooserWindowController.h"
#import "CSCIFilterConfigProxy.h"
#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>

@interface CSLayerFiltersViewController ()

@end

@implementation CSLayerFiltersViewController
@synthesize baseLayer = _baseLayer;
@synthesize filterArrayName = _filterArrayName;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


-(NSString *)filterArrayName
{
    return _filterArrayName;
}

-(void)setFilterArrayName:(NSString *)filterArrayName
{
    _filterArrayName = filterArrayName;
    if (self.baseLayer)
    {
        [self.filterArrayController bind:@"contentArray" toObject:self.baseLayer withKeyPath:filterArrayName options:nil];
    }
}

-(CALayer *)baseLayer
{
    return _baseLayer;
}

-(void) setBaseLayer:(CALayer *)baseLayer
{
    _baseLayer = baseLayer;
    if (self.filterArrayName)
    {
        [self.filterArrayController bind:@"contentArray" toObject:baseLayer withKeyPath:self.filterArrayName options:nil];
    }
}



-(IBAction)addFilterAction:(NSSegmentedControl *)sender
{
    
    NSString *filterName = [CSFilterChooserWindowController run];
    if (!filterName)
    {
        return;
    }
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    
    if (!newFilter)
    {
        return;
    }
    
    [newFilter setDefaults];
    NSString *filterID = NSUUID.UUID.UUIDString;
    newFilter.name = filterID;
    NSArray *cFilters = [self.baseLayer valueForKeyPath:self.filterArrayName];
    if (!cFilters)
    {
        [self.baseLayer setValue:@[] forKeyPath:self.filterArrayName];
    }
    
    [CATransaction begin];

    [self.filterArrayController addObject:newFilter];
    [CATransaction commit];
}


-(IBAction)deleteFilterAction:(NSSegmentedControl *)sender
{
    [CATransaction begin];
    [self.filterArrayController removeObjectAtArrangedObjectIndex:self.filterArrayController.selectionIndex];
    [CATransaction commit];
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
    self.userFilterWindow.styleMask =  NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable;
    [self.userFilterWindow setReleasedWhenClosed:NO];
    
    [self.userFilterWindow makeKeyAndOrderFront:self.userFilterWindow];
    
}


- (IBAction)configureFilter:(NSSegmentedControl *)sender
{
    
    CIFilter *selectedFilter;
    
    selectedFilter = [self.filterArrayController.arrangedObjects objectAtIndex:self.filterArrayController.selectionIndex];
    
    if (selectedFilter)
    {
        [self openUserFilterPanel:selectedFilter forLayer:self.baseLayer withType:self.filterArrayName];
        
        
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
            [self deleteFilterAction:sender];
            break;
        case 2:
            [self configureFilter:sender];
            break;
        default:
            break;
    }
}
@end

