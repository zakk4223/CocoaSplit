//
//  CSTransitionCIFilter.h
//  CocoaSplit
//
//  Created by Zakk on 3/18/18.
//

#import "CSTransitionBase.h"

@interface CSTransitionCIFilter : CSTransitionBase
@property (assign) bool wholeLayout;
@property (strong) CIFilter *transitionFilter;
@end
