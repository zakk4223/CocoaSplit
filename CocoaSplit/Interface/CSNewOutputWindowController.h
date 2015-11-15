//
//  CSNewOutputWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSStreamServiceProtocol.h"

@class OutputDestination;

@interface CSNewOutputWindowController : NSWindowController

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)addButtonAction:(id)sender;


@property (strong) OutputDestination *outputDestination;

@property (strong) NSString *selectedOutputType;
@property (strong) NSObject<CSStreamServiceProtocol>*streamServiceObject;
@property (strong) NSArray *outputTypes;
@property (weak) IBOutlet NSView *serviceConfigView;
@property (strong) NSViewController *pluginViewController;
@end
