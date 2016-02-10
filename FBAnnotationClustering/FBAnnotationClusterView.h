//
//  FBAnnotationClusterView.h
//
//  Created by Oleksandr Bretsko on 12/7/15.
//  Copyright © 2015 Oleksandr Bretsko. All rights reserved.
//

@import MapKit;
@import Foundation;

#import "FBAnnotationCluster.h"
#import "FBClusteringManager.h"

@interface FBAnnotationClusterView : MKAnnotationView

// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wobjc-property-synthesis"
@property(nonatomic) FBAnnotationCluster *annotation;
//#pragma clang diagnostic pop

@property(nonatomic, strong) FBClusteringManager *clusteringManager;

- (id)initWithAnnotation:(id<MKAnnotation>)annotation
       clusteringManager:(FBClusteringManager *)clusteringManager;

@property(nonatomic, strong) NSString *key;
@property(nonatomic, strong) CATextLayer *textLayer;

@end
