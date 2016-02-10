//
//  FBAnnotationCluster.h
//  AnnotationClustering
//
//  Created by Filip Bec on 06/01/14.
//  Copyright (c) 2014 Infinum Ltd. All rights reserved.
//

@import Foundation;
@import MapKit;
#import "FBPointAnnotation.h"

/**
 Class that is used to display annotation clusters.
 */
@interface FBAnnotationCluster : NSObject <MKAnnotation>

/// Coordinate of the annotation. It will always be set.
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;

/// Title of the annotation. Default is @c nil, but can be set.
@property(nonatomic, copy) NSString *title;

/// Subtitle of the annotation. Default is @c nil, but can be set.
@property(nonatomic, copy) NSString *subtitle;

/// Array of the annotations that are represented with this cluster.
@property(nonatomic, strong) NSArray *annotations;

@property(nonatomic, assign) enum AnnotationType type;

@property(nonatomic, assign) BOOL animated;

@end
