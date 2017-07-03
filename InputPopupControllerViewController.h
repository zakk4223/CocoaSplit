//
//  InputPopupControllerViewController.h
//  CocoaSplit
//
//  Created by Zakk on 7/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class InputSource;

@interface InputPopupControllerViewController : NSViewController <NSWindowDelegate, NSTableViewDelegate>


@property (strong) NSWindow *transitionFilterWindow;
@property (strong) NSWindow *userFilterWindow;
@property (strong) NSWindow *screenCropWindow;
@property (weak) InputSource *inputSource;
@property (strong) NSDictionary *inputConstraintMap;
@property (strong) NSArray *constraintSortDescriptors;

@property (assign) NSString *selectedVideoType;
@property (weak) IBOutlet NSTableView *sourceFilterTableView;
@property (weak) IBOutlet NSTableView *backgroundFilterTableView;
@property (weak) IBOutlet NSTableView *layerFilterTableView;

@property (assign) bool sourceTableHasSelection;
@property (assign) bool backgroundTableHasSelection;
@property (assign) bool layerTableHasSelection;

@property (strong) NSMutableDictionary *availableTransitions;

@property (strong) NSArray *compositionFilterNames;


- (IBAction)configureFilter:(NSSegmentedControl *)sender;

- (IBAction)resetConstraints:(id)sender;

- (IBAction)removeFilter:(NSSegmentedControl *)sender;


- (IBAction)filterControlAction:(id)sender;

- (IBAction)deleteMultiSource:(id)sender;
-(void)openTransitionFilterPanel:(CIFilter *)forFilter;
-(IBAction) configureInputTransition:(NSButton *)sender;

- (IBAction)scriptSaveAll:(id)sender;

- (IBAction)addFilterAction:(NSSegmentedControl *)sender;

-(IBAction) clearGradient:(NSButton *)sender;

@property (weak) IBOutlet NSArrayController *multiSourceController;
@property (weak) IBOutlet NSArrayController *currentEffectsController;
@property (weak) IBOutlet NSWindow *cropSelectionWindow;
@property (weak) IBOutlet NSView *sourceConfigView;
@property (strong) IBOutlet NSObjectController *inputobjctrl;
@property (strong) NSViewController *inputConfigViewController;
@property (strong) NSArray *scriptTypes;
@property (strong) NSArray *scriptKeys;
@property (unsafe_unretained) IBOutlet NSTextView *scriptTextView;
@property (weak) IBOutlet NSTableView *scriptTableView;


@end
