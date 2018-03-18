//
//  CSTransitionButton.h
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import <Cocoa/Cocoa.h>


@class CSTransitionCollectionItem;

@interface CSTransitionButton : NSControl
@property (weak) IBOutlet CSTransitionCollectionItem *viewController;
@property (assign) bool mouseisDown;

@end
