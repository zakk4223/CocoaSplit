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

@interface InputPopupControllerViewController : NSViewController <NSPopoverDelegate, NSWindowDelegate, NSTableViewDelegate>

@property (strong) IBOutlet NSWindow *popupWIndow;

@property (strong) NSPopover *myPopover;
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


- (IBAction)configureFilter:(NSButton *)sender;

- (IBAction)resetConstraints:(id)sender;

- (IBAction)removeFilter:(NSButton *)sender;



- (IBAction)deleteMultiSource:(id)sender;
-(void)openTransitionFilterPanel:(CIFilter *)forFilter;
-(IBAction) configureInputTransition:(NSButton *)sender;


- (IBAction)addFilterAction:(NSButton *)sender;

@property (weak) IBOutlet NSArrayController *multiSourceController;
@property (weak) IBOutlet NSArrayController *currentEffectsController;
@property (weak) IBOutlet NSWindow *cropSelectionWindow;
@property (weak) IBOutlet NSView *sourceConfigView;
@property (strong) IBOutlet NSObjectController *inputobjctrl;

@end
