//
//  CSTransitionCIFilter.h
//  CocoaSplit
//
//  Created by Zakk on 3/18/18.
//

#import "CSTransitionBase.h"

@protocol CSTransitionCIFilterExport <JSExport>
@property (assign) bool wholeLayout;
@property (strong) CIFilter *transitionFilter;
@property (strong) CATransition *realTransition;
@end

@interface CSTransitionCIFilter : CSTransitionBase <CSTransitionCIFilterExport>
@property (assign) bool wholeLayout;
@property (strong) CIFilter *transitionFilter;
@property (strong) CATransition *realTransition;

@end
