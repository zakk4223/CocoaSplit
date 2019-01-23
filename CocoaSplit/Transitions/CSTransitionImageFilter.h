//
//  CSTransitionImageFilter.h
//  CocoaSplit
//
//  Created by Zakk on 1/23/19.
//

#import "CSTransitionBase.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CSTransitionImageFilterExport <JSExport>
@property (strong) CIFilter *filter;
@property (assign) float realDuration;
@property (assign) float realInDuration;
@property (assign) float realOutDuration;
@property (strong) NSNumber *inDuration;
@property (strong) NSNumber *outDuration;
@end

@interface CSTransitionImageFilter : CSTransitionBase <CSTransitionImageFilterExport>
@property (strong) CIFilter *filter;
@property (assign) float realDuration;
@property (assign) float realInDuration;
@property (assign) float realOutDuration;
@property (strong) NSNumber *inDuration;
@property (strong) NSNumber *outDuration;
@end

NS_ASSUME_NONNULL_END
