//
//  CSAddSequenceItemPopupViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSAddSequenceItemPopupViewController : NSViewController
{
    NSArray *_sequenceItemTypes;
}

@property (nonatomic,copy) void (^addSequenceItem)(Class sequenceItemClass);

@property (readonly) NSArray *sequenceItemTypes;
@property (weak) IBOutlet NSTableView *sequenceItemTypesTableView;
- (IBAction)sequenceItemClicked:(id)sender;

@end
