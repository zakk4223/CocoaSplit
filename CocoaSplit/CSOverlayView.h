//
//  CSOverlayView.h
//  CocoaSplit
//
//  Created by Zakk on 8/25/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum window_resize_type_t {
    
    kResizeNone = 0,
    kResizeTop = 1 << 0,
    kResizeRight = 1<<1,
    kResizeBottom = 1<<2,
    kResizeLeft = 1<<3
    
} window_resize_type;

@interface CSOverlayView : NSView

@property (strong) NSButton *endButton;

@end
