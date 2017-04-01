//
//  CSGridView.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSGridView : NSView
@property (assign) NSInteger minimumRows;
@property (assign) NSInteger minimumColumns;
@property (strong) NSColor *backgroundColor;

@end
