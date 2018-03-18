//
//  CSTransitionCollectionItem.h
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import <Cocoa/Cocoa.h>
#import "CSTransitionButton.h"

@interface CSTransitionCollectionItem : NSCollectionViewItem
-(void)transitionClicked;
@property (weak) IBOutlet CSTransitionButton *transitionButton;

@end
