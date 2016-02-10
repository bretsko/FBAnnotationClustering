//
//  FBPointAnnotation.h
//  Pods
//
//  Created by Admin on 2/10/16.
//
//

@import MapKit;
NS_ENUM(NSUInteger, AnnotationType){typeA, typeB, typeC, typeD, typeE};

@interface FBPointAnnotation : MKPointAnnotation

@property (nonatomic, assign) enum AnnotationType type;

@end

