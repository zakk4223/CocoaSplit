//
//  CSAddSequenceItemPopupViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSequenceItem.h"
#import "CSSequenceItemViewController.h"

@interface CSAddSequenceItemPopupViewController : NSViewController
{
    CSSequenceItemViewController *_itemController;

}

@property (weak) IBOutlet NSView *itemConfigView;

@property (nonatomic,copy) void (^addSequenceItem)(CSSequenceItem *sequenceItemClass);

@property (strong) CSSequenceItem *editItem;

- (IBAction)saveButtonClicked:(id)sender;
- (IBAction)cancelButtonClicked:(id)sender;

-(instancetype)initWithSequenceItem:(CSSequenceItem *)item;

@end
