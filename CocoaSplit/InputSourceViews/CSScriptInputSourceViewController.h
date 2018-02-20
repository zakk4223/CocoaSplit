//
//  CSScriptInputSourceViewController.h
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSScriptInputSource.h"

@interface CSScriptInputSourceViewController : NSViewController
@property (weak) CSScriptInputSource *inputSource;

@property (strong) IBOutlet NSObjectController *inputSourceController;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (strong) NSArray *scriptTypes;
@property (strong) NSArray *scriptKeys;


@end
