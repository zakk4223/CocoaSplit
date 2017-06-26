//
//  CIFilterJSExport.h
//  CocoaSplit
//
//  Created by Zakk on 6/21/17.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CIFilterJSExport <JSExport>

@property (readonly, nonatomic, nullable) CIImage *outputImage NS_AVAILABLE(10_10, 5_0);

/* The name of the filter. On OSX and iOS 10, this property is read-write.
 * This can be useful when using CIFilters with CoreAnimation or SceneKit.
 * For example, to set an attribute of a filter attached to a layer,
 * a unique path such as "filters.myExposureFilter.inputEV" could be used.
 * CALayer animations may also access filter attributes via key-paths. */
@property (nonatomic, copy) NSString *name;
- (NSString *)name NS_AVAILABLE(10_5,5_0);
- (void)setName:(NSString *)aString NS_AVAILABLE(10_5,10_0);

/* The 'enabled' property is used only by CoreAnimation and is animatable.
 * In Core Animation, a CIFilter only applied to its input when this
 * property is set to true. */
@property (getter=isEnabled) BOOL enabled NS_AVAILABLE_MAC(10_5);


/** Returns an array containing the names of all inputs in the filter. */
@property (nonatomic, readonly) NSArray<NSString *> *inputKeys;

/** Returns an array containing the names of all outputs in the filter. */
@property (nonatomic, readonly) NSArray<NSString *> *outputKeys;

/** Sets all inputs to their default values (where default values are defined, other inputs are left as-is). */
- (void)setDefaults;

/** Returns a dictionary containing key/value pairs describing the filter. (see description of keys below) */
@property (nonatomic, readonly) NSDictionary<NSString *,id> *attributes;


/** Used by CIFilter subclasses to apply the array of argument values 'args' to the kernel function 'k'. The supplied arguments must be type-compatible with the function signature of the kernel.
 
 The key-value pairs defined by 'dict' (if non-nil) are used to control exactly how the kernel is evaluated. Valid keys include:
 kCIApplyOptionExtent: the size of the produced image. Value is a four element NSArray [X Y WIDTH HEIGHT].
 kCIApplyOptionDefinition: the Domain of Definition of the produced image. Value is either a CIFilterShape object, or a four element NSArray defining a rectangle.
 @param  k         CIKernel of the filter
 @param  args      Array of arguments that are applied to the kernel
 @param  dict      Array of additional options
 */
- (nullable CIImage *)apply:(CIKernel *)k
                  arguments:(nullable NSArray *)args
                    options:(nullable NSDictionary<NSString *,id> *)dict NS_AVAILABLE_MAC(10_4);

/** Similar to above except that all argument values and option key-value are specified inline. The list of key-value pairs must be terminated by the 'nil' object. */
- (nullable CIImage *)apply:(CIKernel *)k, ... NS_REQUIRES_NIL_TERMINATION NS_AVAILABLE_MAC(10_4) NS_SWIFT_UNAVAILABLE("");

@end


/** Methods to register a filter and get access to the list of registered filters
 Use these methods to create filters and find filters. */
@interface CIFilter (CIFilterRegistry)

/** Creates a new filter of type 'name'.
 On OSX, all input values will be undefined.
 On iOS, all input values will be set to default values. */
+ (nullable CIFilter *) filterWithName:(NSString *) name;

/** Creates a new filter of type 'name'.
 The filter's input parameters are set from the list of key-value pairs which must be nil-terminated.
 On OSX, any of the filter input parameters not specified in the list will be undefined.
 On iOS, any of the filter input parameters not specified in the list will be set to default values. */
+ (nullable CIFilter *)filterWithName:(NSString *)name
                        keysAndValues:key0, ... NS_REQUIRES_NIL_TERMINATION NS_SWIFT_UNAVAILABLE("");

/** Creates a new filter of type 'name'.
 The filter's input parameters are set from the dictionary of key-value pairs.
 On OSX, any of the filter input parameters not specified in the dictionary will be undefined.
 On iOS, any of the filter input parameters not specified in the dictionary will be set to default values. */
+ (nullable CIFilter *)filterWithName:(NSString *)name
                  withInputParameters:(nullable NSDictionary<NSString *,id> *)params NS_AVAILABLE(10_10, 8_0);

/** Returns an array containing all published filter names in a category. */
+ (NSArray<NSString *> *)filterNamesInCategory:(nullable NSString *)category;

/** Returns an array containing all published filter names that belong to all listed categories. */
+ (NSArray<NSString *> *)filterNamesInCategories:(nullable NSArray<NSString *> *)categories;


/** Publishes a new filter called 'name'.
 
 The constructor object 'anObject' should implement the filterWithName: method.
 That method will be invoked with the name of the filter to create.
 The class attributes must have a kCIAttributeFilterCategories key associated with a set of categories.
 @param   attributes    Dictionary of the registration attributes of the filter. See below for attribute keys.
 */
+ (void)registerFilterName:(NSString *)name
               constructor:(id<CIFilterConstructor>)anObject
           classAttributes:(NSDictionary<NSString *,id> *)attributes NS_AVAILABLE(10_4, 9_0);

/** Returns the localized name of a filter for display in the UI. */
+ (nullable NSString *)localizedNameForFilterName:(NSString *)filterName NS_AVAILABLE(10_4, 9_0);

/** Returns the localized name of a category for display in the UI. */
+ (NSString *)localizedNameForCategory:(NSString *)category NS_AVAILABLE(10_4, 9_0);

/** Returns the localized description of a filter for display in the UI. */
+ (nullable NSString *)localizedDescriptionForFilterName:(NSString *)filterName NS_AVAILABLE(10_4, 9_0);

/** Returns the URL to the localized reference documentation describing the filter.
 
 The URL can be a local file or a remote document on a webserver. It is possible, that this method returns nil (like filters that predate this feature). A client of this API has to handle this case gracefully. */
+ (nullable NSURL *)localizedReferenceDocumentationForFilterName:(NSString *)filterName NS_AVAILABLE(10_4, 9_0);

@end
NS_ASSUME_NONNULL_END

JSEXPORT_PROTO(CIFilterJSExport)

