//
//  CSTransitionInput.h
//  CocoaSplit
//
//  Created by Zakk on 3/27/18.
//

#import "CSTransitionBase.h"


@protocol CSTransitionInputExport <JSExport>
@property (strong) NSObject<CSInputSourceProtocol> *inputSource;
@property (strong) NSNumber *holdDuration;
@property (assign) bool waitForMedia;
@property (assign) float realHoldDuration;
@property (strong) CSTransitionBase *preTransition;
@property (strong) CSTransitionBase *postTransition;

@end

@interface CSTransitionInput : CSTransitionBase <CSTransitionInputExport>
@property (strong) NSNumber *holdDuration;
@property (assign) float realHoldDuration;
@property (strong) NSObject<CSInputSourceProtocol> *inputSource;
@property (assign) bool waitForMedia;
@property (strong) CSTransitionBase *preTransition;
@property (strong) CSTransitionBase *postTransition;
@end
