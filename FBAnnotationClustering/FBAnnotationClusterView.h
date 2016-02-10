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

@property(nonatomic) FBAnnotationCluster *annotation;
@property(nonatomic, strong) FBClusteringManager *clusteringManager;
@property(nonatomic, strong) NSString *key;
@property(nonatomic, strong) CATextLayer *textLayer;

- (id)initWithAnnotation:(id<MKAnnotation>)annotation
       clusteringManager:(FBClusteringManager *)clusteringManager;

@end
