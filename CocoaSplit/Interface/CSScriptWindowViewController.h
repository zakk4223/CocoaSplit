//
//  CSScriptWindowViewController.h
//  CocoaSplit
//
//  Created by Zakk on 4/7/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSequenceActivatorViewController.h"
#import "CSGridView.h"

@interface CSScriptWindowViewController : NSWindowController
{
    CSSequenceActivatorViewController *_sequenceViewController;
}
@property (weak) IBOutlet CSGridView *gridView;
@property (strong) NSArray *sequences;

@end
