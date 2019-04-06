//
//  CSNewOutputWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSStreamServiceProtocol.h"
#import "CompressionSettingsPanelController.h"

@class OutputDestination;

@interface CSNewOutputWindowController : NSWindowController
{
    NSMenu *_tracksMenu;
}
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)addButtonAction:(id)sender;
- (IBAction)openCompressorEdit:(id)sender;

@property (strong) IBOutlet NSObjectController *outputObjectController;

@property (strong) OutputDestination *outputDestination;

@property (strong) NSString *selectedOutputType;
@property (strong) NSObject<CSStreamServiceProtocol>*streamServiceObject;
@property (strong) NSArray *outputTypes;
@property (strong) IBOutlet NSView *serviceConfigView;
@property (strong) NSViewController *pluginViewController;
@property (strong) NSMutableDictionary *compressors;
@property (strong) CompressionSettingsPanelController *compressionPanelController;
@property (strong) NSString *buttonLabel;

@property (nonatomic, copy) void (^windowDone)(NSModalResponse response, CSNewOutputWindowController *windowController);

@property (strong) IBOutlet NSDictionaryController *audioTracksDictionaryController;
@property (readonly) NSArray *trackSortDescriptors;


@end
