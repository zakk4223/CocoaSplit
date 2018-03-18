//
//  CSTransitionSwitcherView.h
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSViewController.h"

@interface CSTransitionSwitcherView : CSViewController
@property (weak) IBOutlet NSCollectionView *collectionView;
- (IBAction)addTransitionClicked:(id)sender;
@property (weak) IBOutlet NSObject *parentObjectController;
@property (strong) NSString *transitionArrayKeyPath;
@property (strong) IBOutlet NSArrayController *transitionsArrayController;
@property (strong) NSMutableArray *blah;
@end
