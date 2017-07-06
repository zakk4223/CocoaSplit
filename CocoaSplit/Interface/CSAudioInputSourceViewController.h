//
//  CSAudioInputSourceViewController.h
//  CocoaSplit
//
//  Created by Zakk on 7/5/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSAudioInputSource.h"

@interface CSAudioInputSourceViewController : NSViewController
@property (weak) CSAudioInputSource *inputSource;

@property (strong) IBOutlet NSObjectController *inputSourceController;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (strong) NSArray *scriptTypes;
@property (strong) NSArray *scriptKeys;

@end
