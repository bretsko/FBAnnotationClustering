//
//  FBViewController.m
//  AnnotationClustering
//
//  Created by Filip Bec on 06/04/14.
//  Copyright (c) 2014 Infinum Ltd. All rights reserved.
//

@import MapKit;
#import "FBViewController.h"

#define kNUMBER_OF_LOCATIONS 1000
#define kFIRST_LOCATIONS_TO_REMOVE 50

@interface FBViewController ()

@property(weak, nonatomic) IBOutlet MKMapView *mapView;
@property(weak, nonatomic) IBOutlet UILabel *numberOfAnnotationsLabel;
@property(nonatomic, assign) NSUInteger numberOfLocations;
@property(nonatomic, strong) FBClusteringManager *clusteringManager;
@property(strong, nonatomic) NSMutableArray *annotationsArray;

@end

@implementation FBViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.annotationsArray = [self randomLocationsWithCount:kNUMBER_OF_LOCATIONS];
  self.numberOfLocations = kNUMBER_OF_LOCATIONS;
  [self updateLabelText];

  self.clusteringManager =
      [[FBClusteringManager alloc] initWithAnnotations:self.annotationsArray andClusteringFactor:15];
  self.clusteringManager.delegate = self;

  self.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);

  [self reloadClusteringAnimated:YES];
}

- (IBAction)ClusterScalingSlider:(UISlider *)sender {
  [self.clusteringManager setClusteringFactor:[sender value]];

    self.clusteringManager =
    [[FBClusteringManager alloc] initWithAnnotations:self.annotationsArray andClusteringFactor:[sender value]];
    self.clusteringManager.delegate = self;

    [self reloadClusteringAnimated:YES];
    //[self reloadClusteringAnimated:NO];
  //   [self.mapView reloadInputViews];
}

#pragma mark - Utility

- (IBAction)addNewAnnotations:(id)sender {
  self.annotationsArray = [self randomLocationsWithCount:kNUMBER_OF_LOCATIONS];
  [self.clusteringManager addAnnotations:self.annotationsArray];

  self.numberOfLocations += kNUMBER_OF_LOCATIONS;
  [self updateLabelText];
  [self reloadClusteringAnimated:NO];
}

- (NSMutableArray *)randomLocationsWithCount:(NSUInteger)count {
  NSMutableArray *array = [NSMutableArray array];
  for (int i = 0; i < count; i++) {
    int c = i;
    if (i > 4) {
      c = i % 4;
    }
    FBPointAnnotation *annotation = [FBPointAnnotation new];
    annotation.type = c;
    annotation.coordinate =
        CLLocationCoordinate2DMake(drand48() * 40 - 20, drand48() * 80 - 40);
    [array addObject:annotation];
  }
  return array;
}

- (void)updateLabelText {
  self.numberOfAnnotationsLabel.text =
      [NSString stringWithFormat:@"Sum of all annotations: %lu",
                                 (unsigned long)self.numberOfLocations];
}

#pragma mark - Cluster View Size

- (CGFloat)cellSizeFactorForCoordinator:(FBClusteringManager *)coordinator {
  return 3;
}

#pragma mark - Animation

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

  if ([touches count] == 1) {
    UITouch *touch = [touches anyObject];
    if (touch.view.subviews && [touch tapCount] == 1) {

      FBAnnotationClusterView *selectedAnnotationView;

      if ([touch.view isMemberOfClass:[FBAnnotationClusterView class]]) {
        selectedAnnotationView = (FBAnnotationClusterView *)touch.view;
        [self showClusterAnimated:selectedAnnotationView];
      }
    }
  }
}

- (void)showClusterAnimated:(FBAnnotationClusterView *)annotationView {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{

    NSArray *array = annotationView.annotation.annotations;

    MKMapRect zoomRect = MKMapRectNull;
    for (id<MKAnnotation> annotation in array) {
      MKMapPoint annotationPoint =
          MKMapPointForCoordinate(annotation.coordinate);
      MKMapRect pointRect =
          MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
      zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }

    for (id<MKAnnotation> annotation in array) {
      if ([annotation isMemberOfClass:[FBAnnotationCluster class]]) {

        FBAnnotationCluster *clusterAnnotation =
            (FBAnnotationCluster *)annotation;
        clusterAnnotation.animated = YES;
      }
    }

    [_mapView setVisibleMapRect:zoomRect animated:YES];
    [_mapView removeAnnotation:annotationView.annotation];

  }];
}

- (void)mapView:(MKMapView *)mapView
    didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views {
  [self.clusteringManager firePieChartAnimation];
}

- (void)reloadClusteringAnimated:(BOOL)animated {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    double scale =
        _mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;

    if (animated) {
      for (id<MKAnnotation> annotation in self.annotationsArray) {
        if ([annotation isMemberOfClass:[FBAnnotationCluster class]]) {
          FBAnnotationCluster *clusterAnnotation =
              (FBAnnotationCluster *)annotation;
          clusterAnnotation.animated = YES;
        }
      }
    }

    NSArray *annotations = [self.clusteringManager
        clusteredAnnotationsWithinMapRect:_mapView.visibleMapRect
                            withZoomScale:scale];

    [self.clusteringManager displayAnnotations:annotations onMapView:_mapView];
  }];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
  [self reloadClusteringAnimated:animated];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation {
  static NSString *const AnnotatioViewReuseID = @"AnnotatioViewReuseID";

  MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView
      dequeueReusableAnnotationViewWithIdentifier:AnnotatioViewReuseID];

  if ([annotation isMemberOfClass:[FBAnnotationCluster class]]) {
    FBAnnotationCluster *clusterAnnotation = (FBAnnotationCluster *)annotation;

    FBAnnotationClusterView *clusterAnnotationView =
        [[FBAnnotationClusterView alloc] initWithAnnotation:clusterAnnotation
                                          clusteringManager:_clusteringManager];

    return clusterAnnotationView;

  } else if (!annotationView) {

    FBPointAnnotation *pointAnnotation = (FBPointAnnotation *)annotation;
    annotationView =
        [[MKPinAnnotationView alloc] initWithAnnotation:pointAnnotation
                                        reuseIdentifier:AnnotatioViewReuseID];

    switch (pointAnnotation.type) {
    case typeA: {
      annotationView.pinTintColor = [UIColor darkGrayColor];

      break;
    }
    case typeB: {
      annotationView.pinTintColor = [UIColor redColor];
      break;
    }
    case typeC: {
      annotationView.pinTintColor = [UIColor colorWithRed:(252 / 255.0)
                                                    green:(190 / 255.0)
                                                     blue:(78 / 255.0)
                                                    alpha:1];
      break;
    }
    case typeD: {
      annotationView.pinTintColor = [UIColor colorWithRed:(200 / 255.0)
                                                    green:(233 / 255.0)
                                                     blue:(100 / 255.0)
                                                    alpha:1];
      break;
    }
    case typeE: {
      annotationView.pinTintColor = [UIColor colorWithRed:(140 / 255.0)
                                                    green:(180 / 255.0)
                                                     blue:(110 / 255.0)
                                                    alpha:1];
      break;
    }
    }

    annotationView.animatesDrop = NO;
  }
  return annotationView;
}

@end
