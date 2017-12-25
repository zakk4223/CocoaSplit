//
//  CSSequenceItemTransition.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItem.h"

@interface CSSequenceItemTransition : CSSequenceItem

@property (strong) NSString *transitionName;
@property (strong) NSString *transitionDirection;
@property (strong) CIFilter *transitionFilter;
@property (assign) float transitionDuration;
@property (assign) bool transitionFullScene;


@end
