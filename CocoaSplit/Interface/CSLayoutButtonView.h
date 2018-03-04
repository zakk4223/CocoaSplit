//
//  CSLayoutButtonView.h
//  CocoaSplit
//
//  Created by Zakk on 3/4/18.
//

#import <Cocoa/Cocoa.h>
@class CSLayoutCollectionItem;

@interface CSLayoutButtonView : NSControl
@property (weak) IBOutlet CSLayoutCollectionItem *viewController;
@property (assign) bool mouseisDown;

@end
