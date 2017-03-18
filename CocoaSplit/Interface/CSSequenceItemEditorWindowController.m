//
//  CSSequenceItemEditorWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 3/16/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemEditorWindowController.h"

@interface CSSequenceItemEditorWindowController ()

@end

@implementation CSSequenceItemEditorWindowController


-(instancetype) init
{
    return [self initWithWindowNibName:@"CSSequenceItemEditorWindowController"];
}



-(void)openWithItem:(CSSequenceItem *)editItem usingCloseBlock:(void (^)(NSWindowController *controller))closeBlock;
{
    self.editItem = editItem;
    _itemController = [self.editItem configurationView];
    //self.mainView.subviews = @[];
    

    _closeWindowBlock = closeBlock;
    [self showWindow:nil];
    [self.mainView addSubview:_itemController.view];
    [_itemController.view setFrameOrigin:NSMakePoint(0, self.mainView.frame.size.height - _itemController.view.frame.size.height)];
    NSLog(@"IC VIEW %@ MAIN VIEW %@", NSStringFromRect(_itemController.view.frame), NSStringFromRect(self.mainView.frame));
    
    

}

- (IBAction)cancelEditClicked:(id)sender {
    if (_itemController)
    {
        [_itemController discardEditing];
        [self.editItem updateItemDescription];
    }
    [self close];
}

- (IBAction)saveEditClicked:(id)sender {
    
    if (_itemController)
    {
        [_itemController commitEditing];
        [self.editItem updateItemDescription];

    }
    
    [self close];
}




-(void)windowWillClose:(NSNotification *)notifification
{
    if (_closeWindowBlock)
    {
        _closeWindowBlock(self);
    }
}



- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
