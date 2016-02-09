//
//  FBViewController.m
//  AnnotationClustering
//
//  Created by Filip Bec on 06/04/14.
//  Copyright (c) 2014 Infinum Ltd. All rights reserved.
//

#import "FBAnnotation.h"
#import "FBViewController.h"

#define kNUMBER_OF_LOCATIONS 1000
#define kFIRST_LOCATIONS_TO_REMOVE 50

@interface FBViewController ()

@property(weak, nonatomic) IBOutlet MKMapView *mapView;
@property(weak, nonatomic) IBOutlet UILabel *numberOfAnnotationsLabel;

@property(nonatomic, assign) NSUInteger numberOfLocations;
@property(nonatomic, strong) FBClusteringManager *clusteringManager;

@property(strong, nonatomic) CLLocationManager *locationManager;

//@property (strong, nonatomic) NSFetchedResultsController
//*fetchedResultsController;
//@property (strong, nonatomic) NSManagedObjectContext* managedObjectContext;

@property(strong, nonatomic) NSArray *mapPointArray;

//@property(assign, nonatomic) NSInteger ratingOfPoints;
//@property(assign, nonatomic) BOOL pointHasComments;
//@property(assign, nonatomic) BOOL pointHasDescription;

@property(strong, nonatomic) NSArray *placeArray;

@property(weak, nonatomic) MKAnnotationView *userLocationPin;
@property(weak, nonatomic) MKAnnotationView *aciveAnnotationView;
//@property(assign, nonatomic) CLLocationCoordinate2D coordinateToPin;

@property(weak, nonatomic) MKAnnotationView *annotationView;
@property(strong, nonatomic) NSMutableArray *clusteredAnnotations;

@end

@implementation FBViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.

  NSMutableArray *array = [self randomLocationsWithCount:kNUMBER_OF_LOCATIONS];
  self.numberOfLocations = kNUMBER_OF_LOCATIONS;
  [self updateLabelText];

  // Create clustering manager
  self.clusteringManager =
      [[FBClusteringManager alloc] initWithAnnotations:array];
  self.clusteringManager.delegate = self;

  self.mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
  [self mapView:self.mapView regionDidChangeAnimated:NO];

  NSMutableArray *annotationsToRemove = [[NSMutableArray alloc] init];
  for (int i = 0; i < kFIRST_LOCATIONS_TO_REMOVE; i++) {
    [annotationsToRemove addObject:array[i]];
  }
  [self.clusteringManager removeAnnotations:annotationsToRemove];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  //   NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  //    self.ratingOfPoints = [userDefaults integerForKey:kSettingsRating];
  //    self.pointHasComments = [userDefaults boolForKey:kSettingsComments];
  //    self.pointHasDescription = [userDefaults boolForKey:kSettingsComments];
  [self.mapView removeAnnotations:self.mapView.annotations];
  // [self printPointWithContinent];

  NSLog(@" Points in map array %lu", (unsigned long)[self.mapPointArray count]);
  // NSLog(@" point has comments %@", self.pointHasComments ? @"Yes" : @"No");

  [[self navigationController] setNavigationBarHidden:YES animated:YES];

  // [self loadSettings];

  if (!self.clusteringManager) {

    [[NSOperationQueue new] addOperationWithBlock:^{
      double scale =
          _mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
      self.clusteringManager = [[FBClusteringManager alloc]
          initWithAnnotations:_clusteredAnnotations];

      self.clusteringManager.scale = [[NSNumber alloc] initWithDouble:1.6];

      NSArray *annotations = [self.clusteringManager
          clusteredAnnotationsWithinMapRect:_mapView.visibleMapRect
                              withZoomScale:scale];
      [self.clusteringManager displayAnnotations:annotations
                                       onMapView:_mapView];
    }];
  } else {

    [self reloadClusteringAnimated:NO];
  }
}

#pragma mark - Utility

- (IBAction)addNewAnnotations:(id)sender {
  NSMutableArray *array = [self randomLocationsWithCount:kNUMBER_OF_LOCATIONS];
  [self.clusteringManager addAnnotations:array];

  self.numberOfLocations += kNUMBER_OF_LOCATIONS;
  [self updateLabelText];

  // Update annotations on the map
  [self mapView:self.mapView regionDidChangeAnimated:NO];
}


- (NSMutableArray *)randomLocationsWithCount:(NSUInteger)count {
  NSMutableArray *array = [NSMutableArray array];
  for (int i = 0; i < count; i++) {
      int c = i;
      if (i > 4) {
      c = i%4;
      }
    FBAnnotation *annotation = [FBAnnotation new];
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
  return 1.5;
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

    for (FBAnnotation *annotation in array) {
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
    NSArray *annotations = [self.clusteringManager
        clusteredAnnotationsWithinMapRect:_mapView.visibleMapRect
                            withZoomScale:scale];
    if (animated) {
      for (FBAnnotation *annotation in annotations) {
        if ([annotation isMemberOfClass:[FBAnnotationCluster class]]) {
          FBAnnotationCluster *clusterAnnotation =
              (FBAnnotationCluster *)annotation;
          clusterAnnotation.animated = YES;
        }
      }
    }

    [self.clusteringManager displayAnnotations:annotations onMapView:_mapView];
  }];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
  [[NSOperationQueue new] addOperationWithBlock:^{
    double scale =
        self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
    NSArray *annotations = [self.clusteringManager
        clusteredAnnotationsWithinMapRect:mapView.visibleMapRect
                            withZoomScale:scale];

    [self.clusteringManager displayAnnotations:annotations onMapView:mapView];
  }];
  [self reloadClusteringAnimated:animated];
}



- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation {
  static NSString *const AnnotatioViewReuseID = @"AnnotatioViewReuseID";

  MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView
      dequeueReusableAnnotationViewWithIdentifier:AnnotatioViewReuseID];

  if (!annotationView) {
    annotationView =
        [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                        reuseIdentifier:AnnotatioViewReuseID];
  }

  // This is how you can check if annotation is a cluster
  if ([annotation isKindOfClass:[FBAnnotationCluster class]]) {
    FBAnnotationCluster *cluster = (FBAnnotationCluster *)annotation;
    cluster.title = [NSString
        stringWithFormat:@"%lu", (unsigned long)cluster.annotations.count];

    annotationView.pinTintColor = [UIColor greenColor];
    annotationView.canShowCallout = YES;
  } else {
    annotationView.pinTintColor = [UIColor redColor];
    annotationView.canShowCallout = NO;
  }

  return annotationView;

//      static NSString *identifier = @"Annotation";
//      MKPinAnnotationView *pin = (MKPinAnnotationView *)
//      [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
//      if ([annotation isKindOfClass:[MKUserLocation class]]) {
//  
//          NSString *identifier = @"UserAnnotation";
//  
//          MKAnnotationView *pin = (MKAnnotationView *)
//          [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
//          if (!pin) {
//  
//              pin = [[MKAnnotationView alloc] initWithAnnotation:annotation
//                                                 reuseIdentifier:identifier];
//  
//              pin.canShowCallout = YES;
//          } else {
//              pin.annotation = annotation;
//          }
//  
//          self.userLocationPin = pin;
//          return pin;
//      } else if ([annotation isMemberOfClass:[FBAnnotationCluster class]]) {
//          FBAnnotationCluster *clusterAnnotation = annotation;
//          if (clusterAnnotation.animated) {
//              FBAnnotationClusterView *clusterAnnotationView =
//              [[FBAnnotationClusterView alloc]
//               initWithAnnotation:clusterAnnotation
//               clusteringManager:_clusteringManager];
//              return clusterAnnotationView;
//          } else {
//  
//              FBAnnotationClusterView *clusterAnnotationView =
//              [[FBAnnotationClusterView alloc]
//               initWithAnnotation:clusterAnnotation
//               clusteringManager:_clusteringManager];
//              return clusterAnnotationView;
//          }
//      } else {
//          if (!pin) {
//              pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
//                                                    reuseIdentifier:identifier];
//          }
//          FBAnnotation* fbannotation = (FBAnnotation *)annotation;
//          switch (fbannotation.type) {
//              case typeA: {
//                  pin.pinTintColor = [UIColor darkGrayColor];
//
//                 break;
//              }
//              case typeB: {
//                    pin.pinTintColor = [UIColor redColor];
//                 break;
//              }
//              case typeC: {
//                  pin.pinTintColor = [UIColor colorWithRed:(252 / 255.0)
//                                                     green:(190 / 255.0)
//                                                      blue:(78 / 255.0)
//                                                     alpha:1];
//                 break;
//              }
//              case typeD: {
//                  pin.pinTintColor = [UIColor colorWithRed:(200 / 255.0)
//                                                     green:(233 / 255.0)
//                                                      blue:(100 / 255.0)
//                                                     alpha:1];
//                  break;
//              }
//              case typeE: {
//                  pin.pinTintColor = [UIColor colorWithRed:(140 / 255.0)
//                                                     green:(180 / 255.0)
//                                                      blue:(110 / 255.0)
//                                                     alpha:1];
//                  break;
//              }
//          }
//          pin.animatesDrop = NO;
//  
//          return pin;
//      }
}


@end
