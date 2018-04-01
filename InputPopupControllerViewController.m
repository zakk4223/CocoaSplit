//
//  InputPopupControllerViewController.m
//  CocoaSplit
//
//  Created by Zakk on 7/26/14.
//

#import "InputPopupControllerViewController.h"
#import "InputSource.h"
#import "CSCIFilterConfigProxy.h"
#import "CSFilterChooserWindowController.h"
#import "SourceLayout.h"

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
        
        self.compositionFilterNames = [CIFilter filterNamesInCategory:kCICategoryCompositeOperation];
        
        self.scriptTypes = @[@"After Add", @"Before Delete", @"FrameTick", @"Before Merge", @"After Merge", @"Before Remove", @"Before Replace", @"After Replace"];
        self.scriptKeys = @[@"selection.script_afterAdd", @"selection.script_beforeDelete", @"selection.script_frameTick", @"selection.script_beforeMerge", @"selection.script_afterMerge", @"selection.script_beforeRemove", @"selection.script_beforeReplace", @"selection.script_afterReplace"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorWellActivate:) name:@"CSColorWellActivated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorWellDeactivate:) name:@"CSColorWellDeactivated" object:nil];

    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)awakeFromNib
{
    if (self.inputobjctrl)
    {
        self.inputobjctrl.undoDelegate = self;
    }
}


-(void)performUndoForKeyPath:(NSString *)keyPath usingValue:(id)usingValue
{

    if (!self.undoManager)
    {
        return;
    }
    
    if (!self.inputSource.sourceLayout)
    {
        return;
    }
    
    NSString *propName = [[keyPath componentsSeparatedByString:@"."] lastObject];

    [[self.undoManager prepareWithInvocationTarget:self.inputSource.sourceLayout] modifyUUID:self.inputSource.uuid withBlock:^(NSObject<CSInputSourceProtocol> *input) {
        [input setValue:usingValue forKey:propName];
    }];
    
    NSString *actionName = [self.inputSource undoNameForKeyPath:propName usingValue:usingValue];
    if (actionName)
    {
        [self.undoManager setActionName:actionName];
    }
}


-(void)colorWellActivate:(NSNotification *)notification
{
    NSColorWell *well = notification.object;
    
    if (well.window != self.view.window)
    {
        return;
    }
    
    NSDictionary *bindInfo = [well infoForBinding:@"value"];
    NSString *keyPath = bindInfo[NSObservedKeyPathKey];
    [self.inputobjctrl setValue:well.color forKeyPath:keyPath];
    [self.inputobjctrl pauseUndoForKeyPath:keyPath];
}


-(void)colorWellDeactivate:(NSNotification *)notification
{
    
    
    NSColorWell *well = notification.object;
    
    if (well.window != self.view.window)
    {
        return;
    }
    
    NSDictionary *bindInfo = [well infoForBinding:@"value"];
    NSString *keyPath = bindInfo[NSObservedKeyPathKey];
    [self.inputobjctrl resumeUndoForKeyPath:keyPath];
    [self.inputobjctrl setValue:well.color forKeyPath:keyPath];
}


+(NSSet *)keyPathsForValuesAffectingSelectedVideoType
{
    return [NSSet setWithObjects:@"inputSource", nil];
}


-(void)setInputSource:(InputSource *)inputSource
{
    _inputSource = inputSource;
    
    [self sourceConfigurationView];
    self.backgroundFilterViewController.baseLayer = inputSource.layer;
    self.backgroundFilterViewController.filterArrayName = @"backgroundFilters";
    self.inputFilterViewController.baseLayer = inputSource.layer;
    self.inputFilterViewController.filterArrayName = @"filters";
    self.sourceFilterViewController.baseLayer = inputSource.layer.sourceLayer;
    self.sourceFilterViewController.filterArrayName = @"filters";
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

- (IBAction)scriptSaveAll:(id)sender
{
    [self.inputobjctrl commitEditing];
}



- (IBAction)configureFilter:(NSSegmentedControl *)sender
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


- (IBAction)removeFilter:(NSSegmentedControl *)sender
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


-(void)setSelectedVideoType:(NSString *)selectedVideoType
{
    self.inputSource.selectedVideoType = selectedVideoType;
    [self sourceConfigurationView];
}


-(void)sourceConfigurationView
{

    self.inputConfigViewController  = [self.inputSource sourceConfigurationView];
    
    
    NSView *configView = self.inputConfigViewController.view;
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

- (IBAction)addFilterAction:(NSSegmentedControl *)sender
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
    } else if (tableView == self.scriptTableView) {
        NSString *scriptKey = self.scriptKeys[tableView.selectedRow];
        [self scriptSaveAll:nil];
        [self.scriptTextView bind:@"value" toObject:self.inputobjctrl withKeyPath:scriptKey options:nil];

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



-(IBAction) clearGradient:(NSButton *)sender
{

    [self.undoManager beginUndoGrouping];
    self.inputSource.startColor = nil;
    self.inputSource.stopColor = nil;
    [self.undoManager setActionName:@"Clear Gradient"];
    [self.undoManager endUndoGrouping];
}


-(void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self scriptSaveAll:nil];
}

-(IBAction)scriptUndo:(NSButton *)sender
{
    [self.inputobjctrl discardEditing];
}


- (IBAction)resetConstraints:(id)sender
{
    NSMutableDictionary *oldConstraints = self.inputSource.constraintMap;
    
    [[self.inputSource.sourceLayout.undoManager prepareWithInvocationTarget:self.inputSource.sourceLayout] modifyUUID:self.inputSource.uuid withBlock:^(NSObject<CSInputSourceProtocol> *input) {
        
        ((InputSource *)input).constraintMap = oldConstraints;
    }];
    
    
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
