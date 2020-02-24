//
//  CAAudioInputChannelCell.h
//  CocoaSplit
//
//  Created by Zakk on 2/24/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSAudioLevelView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAAudioInputChannelCell : NSTableCellView
@property (weak) IBOutlet NSTextField *textLabel;

@property (weak) IBOutlet CSAudioLevelView *levelView;

@end

NS_ASSUME_NONNULL_END
