//
//  FBViewController.h
//  AnnotationClustering
//
//  Created by Filip Bec on 06/04/14.
//  Copyright (c) 2014 Infinum Ltd. All rights reserved.
//

@import UIKit;
#import <FBAnnotationClustering.h>

@interface FBViewController
    : UIViewController <MKMapViewDelegate, FBClusteringManagerDelegate>

@end
