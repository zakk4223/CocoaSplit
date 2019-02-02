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
@property (assign) bool transitionAfterPre;
@property (assign) bool wholeLayout;
@property (strong) NSString *inputSourceUUID;
@property (assign) bool autoFit;
-(NSObject<CSInputSourceProtocol> *)getInputSource;
-(void)saveAndClearInputSource;



@end

@interface CSTransitionInput : CSTransitionBase <CSTransitionInputExport>
{
    NSString *_savedInputName;
}
@property (strong) NSNumber *holdDuration;
@property (assign) float realHoldDuration;
@property (strong) NSObject<CSInputSourceProtocol> *inputSource;
@property (strong) NSObject<CSInputSourceProtocol> *configuredInputSource;
@property (strong) NSData *inputSourceSavedata;

@property (assign) bool waitForMedia;
@property (assign) bool transitionAfterPre;
@property (assign) bool wholeLayout;
@property (assign) bool autoFit;
@property (strong) NSString *inputSourceUUID;

-(NSObject<CSInputSourceProtocol> *)getInputSource;
-(void)saveAndClearInputSource;




@end
