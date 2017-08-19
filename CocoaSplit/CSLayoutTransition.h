//
//  CSLayoutTransition.h
//  CocoaSplit
//
//  Created by Zakk on 8/12/17.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"


@protocol CSLayoutTransitionExport <JSExport>
@property (assign) float transitionDuration;
@property (strong) NSString *transitionName;
@property (strong) NSString *transitionDirection;
@property (strong) CIFilter *transitionFilter;
@property (assign) bool transitionFullScene;
@property (strong) SourceLayout *transitionLayout;
@property (assign) float transitionHoldTime;
@property (strong) CSLayoutTransition *preTransition;
@property (strong) CSLayoutTransition *postTransition;

@end

@interface CSLayoutTransition : NSObject <CSLayoutTransitionExport, NSCopying, NSCoding>

@property (assign) float transitionDuration;
@property (strong) NSString *transitionName;
@property (strong) NSString *transitionDirection;
@property (strong) CIFilter *transitionFilter;
@property (assign) bool transitionFullScene;
@property (strong) SourceLayout *transitionLayout;
@property (assign) float transitionHoldTime;
@property (strong) CSLayoutTransition *preTransition;
@property (strong) CSLayoutTransition *postTransition;


@end


