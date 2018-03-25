//
//  CSTransitionCA.h
//  CocoaSplit
//
//  Created by Zakk on 3/16/18.
//

#import "CSTransitionBase.h"

@protocol CSTransitionCAExport <JSExport>
@property (assign) bool wholeLayout;
@property (strong) CATransition *realTransition;
@end

@interface CSTransitionCA : CSTransitionBase <CSTransitionCAExport>
@property (strong) NSString *transitionDirection;
@property (assign) bool wholeLayout;
@property (strong) CATransition *realTransition;


@end
