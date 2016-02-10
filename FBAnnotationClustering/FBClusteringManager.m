//
//  FBClusterManager.m
//  AnnotationClustering
//
//  Created by Filip Bec on 05/01/14.
//  Copyright (c) 2014 Infinum Ltd. All rights reserved.
//

#import "FBClusterViewSegment.h"
#import "FBClusteringManager.h"
#import "FBPointAnnotation.h"
#import "FBQuadTree.h"

static NSString *const kFBClusteringManagerLockName =
    @"co.infinum.clusteringLock";
static NSString *kSettingsRating = @"type";
static NSString *kSettingsClustering = @"clustering";
static NSUInteger clusteringFactor = 55;
#pragma mark - Utility functions

NSInteger FBZoomScaleToZoomLevel(MKZoomScale scale) {
  double totalTilesAtMaxZoom = MKMapSizeWorld.width / 256.0;
  NSInteger zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom);
  NSInteger zoomLevel = MAX(0, zoomLevelAtMaxZoom + floor(log2f(scale) + 0.5));

  return zoomLevel;
}

CGFloat FBCellSizeForZoomScale(MKZoomScale zoomScale) {
  NSInteger zoomLevel = FBZoomScaleToZoomLevel(zoomScale);

  switch (zoomLevel) {
  case 13:
  case 14:
  case 15:
    return 64;
  case 16:
  case 17:
  case 18:
    return 32;
  case 19:
    return 16;

  default:
    return 88;
  }
}

#pragma mark - FBClusteringManager

@interface FBClusteringManager ()

@property(nonatomic, strong) FBQuadTree *tree;
@property(nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation FBClusteringManager

- (id)init {
  return [self initWithAnnotations:nil andClusteringFactor:NULL];
}

- (id)initWithAnnotations:(NSArray *)annotations andClusteringFactor:(NSUInteger)newClusteringFactor{
  self = [super init];
  if (self) {
    _lock = [NSRecursiveLock new];

    self.scale = [[NSNumber alloc] initWithDouble:clusteringFactor / 15 ];
    clusteringFactor = newClusteringFactor;
      _labelFontSize = clusteringFactor;

      _clusterAnnotationViewRadius = 3*clusteringFactor ;

    _numOfInitializedAnnotationViews = 0;
    _slicesArray = [NSMutableArray new];

    _typeAColour =
        [UIColor colorWithRed:0.620 green:0.625 blue:0.612 alpha:1.000];

    _typeBColour =
        [UIColor colorWithRed:0.871 green:0.000 blue:0.126 alpha:1.000];

    _typeCColour =
        [UIColor colorWithRed:0.641 green:0.871 blue:0.533 alpha:1.000];

    _typeDColour =
        [UIColor colorWithRed:0.301 green:0.756 blue:0.274 alpha:1.000];

    _typeEColour =
        [UIColor colorWithRed:0.000 green:1.000 blue:0.050 alpha:1.000];

    _strokeColour = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.000];

    [self addAnnotations:annotations];
  }
  return self;
}

//- (id)initWithAnnotations:(NSArray *)annotations andClusteringFactor:(NSUInteger)clusteringFactor{
//}

- (NSUInteger)clusteringFactor {
  return clusteringFactor;
}

- (void)setClusteringFactor:(NSUInteger)newFactor {
  clusteringFactor = newFactor;
}

- (void)setAnnotations:(NSArray *)annotations {
  self.tree = nil;
  [self addAnnotations:annotations];
}

- (void)addAnnotations:(NSArray *)annotations {
  if (!self.tree) {
    self.tree = [[FBQuadTree alloc] init];
  }

  [self.lock lock];
  for (id<MKAnnotation> annotation in annotations) {
    [self.tree insertAnnotation:annotation];
  }
  [self.lock unlock];
}

- (void)removeAnnotations:(NSArray *)annotations {
  if (!self.tree) {
    return;
  }

  [self.lock lock];
  for (id<MKAnnotation> annotation in annotations) {
    [self.tree removeAnnotation:annotation];
  }
  [self.lock unlock];
}

- (NSArray *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect
                                 withZoomScale:(double)zoomScale {

  return [self clusteredAnnotationsWithinMapRect:rect
                                   withZoomScale:zoomScale
                                      withFilter:nil];
}

- (NSArray *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect
                                 withZoomScale:(double)zoomScale
                                    withFilter:
                                        (BOOL (^)(id<MKAnnotation>))filter {
  double cellSize = FBCellSizeForZoomScale(zoomScale);
  if ([self.delegate
          respondsToSelector:@selector(cellSizeFactorForCoordinator:)]) {
    cellSize *= [self.delegate cellSizeFactorForCoordinator:self];
  }

  double scale = [self.scale doubleValue];
  double scaleFactor = zoomScale / cellSize / scale ;

  NSInteger minX = floor(MKMapRectGetMinX(rect) * scaleFactor);
  NSInteger maxX = floor(MKMapRectGetMaxX(rect) * scaleFactor);
  NSInteger minY = floor(MKMapRectGetMinY(rect) * scaleFactor);
  NSInteger maxY = floor(MKMapRectGetMaxY(rect) * scaleFactor);

  NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];

  [self.lock lock];
  for (NSInteger x = minX; x <= maxX; x++) {
    for (NSInteger y = minY; y <= maxY; y++) {
      MKMapRect mapRect = MKMapRectMake(x / scaleFactor, y / scaleFactor,
                                        1.0 / scaleFactor, 1.0 / scaleFactor);
      FBBoundingBox mapBox = FBBoundingBoxForMapRect(mapRect);

      __block double totalLatitude = 0;
      __block double totalLongitude = 0;

      NSMutableArray *annotations = [[NSMutableArray alloc] init];

      [self.tree enumerateAnnotationsInBox:mapBox
                                usingBlock:^(id<MKAnnotation> obj) {

                                  if (!filter || (filter(obj) == TRUE)) {
                                    totalLatitude += [obj coordinate].latitude;
                                    totalLongitude +=
                                        [obj coordinate].longitude;
                                    [annotations addObject:obj];
                                  }
                                }];

      NSInteger count = [annotations count];

      if (count < clusteringFactor) {
        [clusteredAnnotations addObjectsFromArray:annotations];
      }

      if (count > clusteringFactor - 1) {

        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
            totalLatitude / count, totalLongitude / count);
        FBAnnotationCluster *cluster = [[FBAnnotationCluster alloc] init];
        cluster.coordinate = coordinate;
        cluster.annotations = annotations;
        [clusteredAnnotations addObject:cluster];
      }
    }
  }
  [self.lock unlock];

  _currentlyClusteredAnnotations =
      [NSArray arrayWithArray:clusteredAnnotations];
  _numOfClusteredAnnotations = _currentlyClusteredAnnotations.count;

  return [NSArray arrayWithArray:clusteredAnnotations];
}

- (NSArray *)allAnnotations {
  NSMutableArray *annotations = [[NSMutableArray alloc] init];

  [self.lock lock];
  [self.tree enumerateAnnotationsUsingBlock:^(id<MKAnnotation> obj) {
    [annotations addObject:obj];
  }];
  [self.lock unlock];

  return annotations;
}

- (void)displayAnnotations:(NSArray *)annotations
                 onMapView:(MKMapView *)mapView {

  NSMutableSet *before = [NSMutableSet setWithArray:mapView.annotations];
  MKUserLocation *userLocation = [mapView userLocation];
  if (userLocation) {
    [before removeObject:userLocation];
  }

  NSSet *after = [NSSet setWithArray:annotations];

  NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
  [toKeep intersectSet:after];

  NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
  [toAdd minusSet:toKeep];

  NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
  [toRemove minusSet:after];

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [mapView addAnnotations:[toAdd allObjects]];
    [mapView removeAnnotations:[toRemove allObjects]];

  }];
}

- (void)firePieChartAnimation {
  for (FBClusterViewSegment *slice in self.slicesArray) {
    slice.startAngle = slice.startAngleAnimated;
    slice.endAngle = slice.endAngleAnimated;
  }
}

@end
