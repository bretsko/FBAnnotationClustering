//
//  FBAnnotation.h
//  AnnotationClustering
//
//  Created by Filip Bec on 06/01/14.
//  Copyright (c) 2014 Infinum Ltd. All rights reserved.
//

@import Foundation;
@import MapKit;

NS_ENUM(NSUInteger, AnnotationType){typeA, typeB, typeC, typeD, typeE};

@interface FBAnnotation : NSObject <MKAnnotation>

@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;

@property(nonatomic, assign) NSInteger idPlace;
@property(nonatomic, assign) enum AnnotationType type;

@end
