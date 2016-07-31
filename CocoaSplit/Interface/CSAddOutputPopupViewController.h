//
//  CSAddOutputPopupViewController.h
//  CocoaSplit
//
//  Created by Zakk on 7/29/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSPluginLoader.h"


@interface CSAddOutputPopupViewController : NSViewController <NSTableViewDelegate>
{
    NSArray *_outputTypes;
    
}
@property (weak) IBOutlet NSTableView *outputTypesTableView;
@property (readonly) NSArray *outputTypes;
@property (weak) NSPopover *popover;
@property (nonatomic,copy) void (^addOutput)(Class outputClass);


- (IBAction)inputTableButtonClicked:(id)sender;

@end
