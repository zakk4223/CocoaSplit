//
//  InputPopupControllerViewController.m
//  CocoaSplit
//
//  Created by Zakk on 7/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "InputPopupControllerViewController.h"
#import "InputSource.h"
#import "CSCIFilterConfigProxy.h"
#import "CSFilterChooserWindowController.h"

@interface InputPopupControllerViewController ()

@end

@implementation InputPopupControllerViewController
@synthesize inputSource = _inputSource;


-(instancetype) init
{
    if (self = [super init])
    {
        self = [super initWithNibName:@"InputPopupControllerViewController" bundle:nil];
        self.inputConstraintMap = @{@"Left Edge": @(kCAConstraintMinX),
                                    @"Right Edge": @(kCAConstraintMaxX),
                                    @"Top Edge": @(kCAConstraintMaxY),
                                    @"Bottom Edge": @(kCAConstraintMinY),
                                    @"Horizontal Center": @(kCAConstraintMidX),
                                    @"Vertical Center": @(kCAConstraintMidY),
                                    @"Width": @(kCAConstraintWidth),
                                    @"Height": @(kCAConstraintHeight),
                                    };

        self.constraintSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]];
        self.availableTransitions = [NSMutableDictionary dictionary];

        NSArray *caTransitionNames = @[kCATransitionFade, kCATransitionPush, kCATransitionMoveIn, kCATransitionReveal, @"cube", @"alignedCube", @"flip", @"alignedFlip"];
        NSArray *ciTransitionNames = [CIFilter filterNamesInCategory:kCICategoryTransition];
        
        for (NSString *caName in caTransitionNames)
        {
            [self.availableTransitions setObject:caName forKey:caName];
        }
        
        for (NSString *ciName in ciTransitionNames)
        {
            NSString *niceName = [CIFilter localizedNameForFilterName:ciName];
            [self.availableTransitions setObject:niceName forKey:ciName];
        }
        
        
        //self = [super initWithNibName:@"TestView" bundle:nil];

    }
    
    return self;
}


+(NSSet *)keyPathsForValuesAffectingSelectedVideoType
{
    return [NSSet setWithObjects:@"inputSource", nil];
}


-(void)setInputSource:(InputSource *)inputSource
{
    _inputSource = inputSource;
    
    [self sourceConfigurationView];
    
}

-(InputSource *)inputSource
{
    return _inputSource;
}


-(NSString *)selectedVideoType
{
    
    return self.inputSource.selectedVideoType;
}

-(IBAction) configureInputTransition:(NSButton *)sender
{
    if (self.inputSource.advancedTransition)
    {
        [self openTransitionFilterPanel:self.inputSource.advancedTransition];
    }
}


- (IBAction)configureFilter:(NSButton *)sender
{
    CIFilter *selectedFilter;
    CALayer *useLayer = nil;

    NSString *filterType = @"filters";
    
    if (sender.tag == 1)
    {
        selectedFilter = [self.inputSource.layer.backgroundFilters objectAtIndex:self.backgroundFilterTableView.selectedRow];
        useLayer = self.inputSource.layer;
        filterType = @"backgroundFilters";
    } else if (sender.tag == 2) {
        
        selectedFilter = [self.inputSource.layer.sourceLayer.filters objectAtIndex:self.sourceFilterTableView.selectedRow];
        useLayer = self.inputSource.layer.sourceLayer;
    } else if (sender.tag == 3) {
        selectedFilter = [self.inputSource.layer.filters objectAtIndex:self.layerFilterTableView.selectedRow];
        useLayer = self.inputSource.layer;
    }

    if (selectedFilter)
    {
        [self openUserFilterPanel:selectedFilter forLayer:useLayer withType:filterType];
        
    }
    
    
}


- (IBAction)removeFilter:(NSButton *)sender
{
    CIFilter *selectedFilter;
    
    
    if (sender.tag == 1)
    {
        selectedFilter = [self.inputSource.layer.backgroundFilters objectAtIndex:self.backgroundFilterTableView.selectedRow];
        [self.inputSource deleteBackgroundFilter:selectedFilter.name];
        
    } else if (sender.tag == 2) {
        
        selectedFilter = [self.inputSource.layer.sourceLayer.filters objectAtIndex:self.sourceFilterTableView.selectedRow];
        [self.inputSource deleteSourceFilter:selectedFilter.name];
        
    } else if (sender.tag == 3) {
        selectedFilter = [self.inputSource.layer.filters objectAtIndex:self.layerFilterTableView.selectedRow];
        [self.inputSource deleteLayerFilter:selectedFilter.name];
    }
}


-(void)setSelectedVideoType:(NSString *)selectedVideoType
{
    self.inputSource.selectedVideoType = selectedVideoType;
    [self sourceConfigurationView];
}


-(void)sourceConfigurationView
{

    NSViewController *sourceViewController = [self.inputSource sourceConfigurationView];
    
    
    NSView *configView = sourceViewController.view;
    self.view.hidden = NO;
    
    
    NSArray *currentSubviews = self.sourceConfigView.subviews;
    NSView *currentSubview = currentSubviews.firstObject;
    
    
    if (!configView)
    {
        [currentSubview removeFromSuperview];
    } else if (currentSubview) {
        [[self.sourceConfigView animator] replaceSubview:currentSubview with:configView ];
        [configView setFrameOrigin:NSMakePoint(configView.frame.origin.x, NSMaxY(self.sourceConfigView.frame) - configView.frame.size.height)];
        
    } else {
        [[self.sourceConfigView animator] addSubview:configView];
        [configView setFrameOrigin:NSMakePoint(configView.frame.origin.x, NSMaxY(self.sourceConfigView.frame) - configView.frame.size.height)];
    }
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}




- (void)popoverDidClose:(NSNotification *)notification
{
    
    NSString *closeReason = [[notification userInfo] valueForKey:NSPopoverCloseReasonKey];
            
    if (closeReason && closeReason == NSPopoverCloseReasonStandard)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "after" the popover closes
        //
        self.inputSource.editorController = nil;
    }
    
    [self.inputSource editorPopoverDidClose];
    
    
    
    
}



-(NSString *)bindKeyForAffineTransform:(NSObject *)transform withProxy:(CSCIFilterConfigProxy *)withProxy
{
    NSString *baseBinding = nil;
    
    for (NSString *bindkey in transform.exposedBindings)
    {
        if ([bindkey isEqualToString:@"affineTransform"])
        {
            NSDictionary *bindInfo = [transform infoForBinding:bindkey];
            NSString *bindpath = bindInfo[NSObservedKeyPathKey];
            if (bindpath && [bindpath hasPrefix:@"selection."])
            {
                baseBinding = [bindpath substringFromIndex:@"selection.".length];
                [transform unbind:bindkey];
                [transform bind:bindkey toObject:withProxy withKeyPath:[NSString stringWithFormat:@"baseDict.%@",baseBinding] options:bindInfo[NSOptionsKey]];
                
            }
        }
    }
    
    return baseBinding;
}
-(NSString *)bindKeyForVector:(NSObject *)vector withProxy:(CSCIFilterConfigProxy *)withProxy
{
    NSString *baseBinding = nil;
    
    for (NSString *bindkey in vector.exposedBindings)
    {
        if ([bindkey isEqualToString:@"vector"])
        {
            NSDictionary *bindInfo = [vector infoForBinding:bindkey];
            NSString *bindpath = bindInfo[NSObservedKeyPathKey];
            if (bindpath && [bindpath hasPrefix:@"selection."])
            {
                baseBinding = [bindpath substringFromIndex:@"selection.".length];
                [vector unbind:bindkey];
                [vector bind:bindkey toObject:withProxy withKeyPath:[NSString stringWithFormat:@"baseDict.%@",baseBinding] options:bindInfo[NSOptionsKey]];
                
            }
        }
    }
    
    return baseBinding;
}

-(void)rebindViewControls:(NSView *)forView withProxy:(CSCIFilterConfigProxy *)withProxy
{
    for (NSString *b in forView.exposedBindings)
    {
        
        NSDictionary *bindingInfo = [forView infoForBinding:b];
        
        
        if (!bindingInfo)
        {
            continue;
        }
        
        NSDictionary *bindingOptions = bindingInfo[NSOptionsKey];
        
        NSString *bindPath = bindingInfo[NSObservedKeyPathKey];
        
        NSObject *boundTo = bindingInfo[NSObservedObjectKey];
        
        
        NSString *baseBinding;
        
        
        if ([bindPath hasPrefix:@"selection."])
        {
            baseBinding = [bindPath substringFromIndex:@"selection.".length];
            [forView unbind:b];
            [forView bind:b toObject:withProxy withKeyPath:[NSString stringWithFormat:@"baseDict.%@",baseBinding] options:bindingOptions];

        } else if ([boundTo.className isEqualToString:@"CIMutableVector"]) {
            [self bindKeyForVector:boundTo withProxy:withProxy];
        } else if ([boundTo.className isEqualToString:@"NSMutableAffineTransform"]) {
            [self bindKeyForAffineTransform:boundTo withProxy:withProxy];
            
        }
    }
    
    for (NSView *subview in forView.subviews)
    {
        [self rebindViewControls:subview withProxy:withProxy];
        
    }
    

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

        [self rebindViewControls:filterView withProxy:filterProxy];
    }
    
    
    self.userFilterWindow = [[NSWindow alloc] init];

    self.userFilterWindow.delegate = self;
    [self.userFilterWindow setContentSize:filterView.bounds.size];
    [self.userFilterWindow.contentView addSubview:filterView];
    self.userFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.userFilterWindow setReleasedWhenClosed:NO];
    
    [self.userFilterWindow makeKeyAndOrderFront:self.userFilterWindow];
    
}

- (IBAction)addFilterAction:(NSButton *)sender
{
    NSString *filterName = [CSFilterChooserWindowController run];
    
    if (sender.tag == 1)
    {
        [self.inputSource addBackgroundFilter:filterName];
    } else if (sender.tag == 2) {
        [self.inputSource addSourceFilter:filterName];
    } else if (sender.tag == 3) {
        [self.inputSource addLayerFilter:filterName];
    }
}


-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    
    if (tableView == self.backgroundFilterTableView)
    {
        if (tableView.selectedRow > -1)
        {
            self.backgroundTableHasSelection = YES;
        } else {
            self.backgroundTableHasSelection = NO;
        }
    } else if (tableView == self.sourceFilterTableView) {
        if (tableView.selectedRow > -1)
        {
            self.sourceTableHasSelection = YES;
        } else {
            self.sourceTableHasSelection = NO;
        }

    } else if (tableView == self.layerFilterTableView) {
        if (tableView.selectedRow > -1)
        {
            self.layerTableHasSelection = YES;
        } else {
            self.layerTableHasSelection = NO;
        }
    }
}

-(void)openTransitionFilterPanel:(CIFilter *)forFilter
{
    if (!forFilter)
    {
        return;
    }
    
    IKFilterUIView *filterView = [forFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    
    self.transitionFilterWindow = [[NSWindow alloc] init];
    self.transitionFilterWindow.delegate = self;
    [self.transitionFilterWindow setContentSize:filterView.bounds.size];
    [self.transitionFilterWindow.contentView addSubview:filterView];
    
    self.transitionFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.transitionFilterWindow setReleasedWhenClosed:NO];
    
    [self.transitionFilterWindow makeKeyAndOrderFront:self.transitionFilterWindow];
    
}





- (IBAction)resetConstraints:(id)sender
{
    [self.inputSource resetConstraints];
    
}

- (IBAction)deleteMultiSource:(id)sender
{

    NSTableView *bTable = (NSTableView *)sender;
    NSInteger deleteRow = [bTable clickedRow];
    
    InputSource *toConfig = [self.multiSourceController.arrangedObjects objectAtIndex:deleteRow];
    

    InputPopupControllerViewController *windowController = [[InputPopupControllerViewController alloc] init];
    
    windowController.inputSource = toConfig;
    NSWindow *configWindow = [[NSWindow alloc] init];
    
    NSRect newFrame = [configWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, windowController.view.frame.size.width, windowController.view.frame.size.height)];
    
    [configWindow setFrame:newFrame display:NO];
    
    [configWindow setReleasedWhenClosed:NO];
    
    
    [configWindow.contentView addSubview:windowController.view];
    configWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", windowController.inputSource.name];
    configWindow.delegate = windowController.inputSource;
    
    configWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    
    windowController.inputSource.editorWindow = configWindow;
    windowController.inputSource.editorController = windowController;
    [configWindow makeKeyAndOrderFront:NSApp];
}


@end
