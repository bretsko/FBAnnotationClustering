//
//  FBAnnotationClusterView.m
//
//  Created by Oleksandr Bretsko on 12/7/15.
//  Copyright © 2015 Oleksandr Bretsko. All rights reserved.
//

@import QuartzCore;
@import CoreText;

#import "FBAnnotationClusterView.h"
#import "FBClusterViewSegment.h"

@interface FBAnnotationClusterView ()

@property(strong, nonatomic) CALayer *containerLayer;
@property(strong, nonatomic) NSMutableArray *segmentSizesArray;
@property(strong, nonatomic) NSMutableArray *segmentsArray;
@property(nonatomic, strong) NSArray *sliceColors;
- (void)updateSlices;

@end

@implementation FBAnnotationClusterView
@dynamic annotation;
- (id)initWithAnnotation:(FBAnnotationCluster *)annotation
       clusteringManager:(FBClusteringManager *)clusteringManager {

  _clusteringManager = clusteringManager;

  self = [super initWithAnnotation:annotation reuseIdentifier:nil];
  if (self != nil) {

    self.frame =
        CGRectMake(0, 0, _clusteringManager.clusterAnnotationViewRadius,
                   _clusteringManager.clusterAnnotationViewRadius);

    self.backgroundColor = [UIColor clearColor];

    if (annotation.animated) {

      [self updateSlices];
    } else {

      self.image = [self drawPieChartImageInRect:self.frame];
    }

    NSString *string = [[NSString alloc]
        initWithFormat:@"%ld", (long)self.annotation.annotations.count];

    CGPoint point =
        CGPointMake(self.bounds.origin.x + self.bounds.size.width / 1.5,
                    self.bounds.origin.y + self.bounds.size.height / 1.5);

    CATextLayer *textLayer =
        [self constructTextLayerAtPoint:point WithString:string];

    [self.layer addSublayer:textLayer];
  }
  return self;
}

- (void)updateSlices {

  _containerLayer.frame = self.bounds;

  int radius =
      MIN(_containerLayer.frame.size.height, _containerLayer.frame.size.width) /
      2;

  NSArray *coloursArray =
      [[NSArray alloc] initWithObjects:_clusteringManager.typeAColour,
                                       _clusteringManager.typeBColour,
                                       _clusteringManager.typeCColour,
                                       _clusteringManager.typeDColour,
                                       _clusteringManager.typeEColour,
                                       _clusteringManager.strokeColour, nil];

  [self calculatePieChartSegmentSizes];

  __block CGFloat previousSegmentAngle;
  CGPoint center =
      CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  [_segmentsArray
      enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        NSMutableDictionary *segment = [obj mutableCopy];

        NSNumber *segmentType = segment[@"type"];

        NSNumber *segmentSize = segment[@"size"];

        UIColor *color = coloursArray[segmentType.unsignedIntegerValue];

        CGFloat startAngle = 0.0;
        CGFloat endAngle = 0.0;

        if (idx == 0) {
          startAngle = 0;
        } else if (previousSegmentAngle) {

          startAngle = previousSegmentAngle;
        }

        if (idx == _segmentsArray.count - 1) {
          endAngle = 2 * M_PI;
          previousSegmentAngle = 0;

        } else {
          endAngle = 2 * M_PI * segmentSize.doubleValue;
          previousSegmentAngle = endAngle;
        }
        FBClusterViewSegment *slice = [FBClusterViewSegment layer];

        slice.frame = self.frame;

        slice.startAngleAnimated = startAngle;
        slice.endAngleAnimated = endAngle;
        slice.segmentSize = segmentSize;

        slice.fillColor = color;
        slice.strokeColor = [UIColor clearColor];
        // slice.strokeColor = [_clusteringManager strokeColour];
        // slice.strokeWidth = 0.1;

        UIBezierPath *aPath = [UIBezierPath bezierPath];

        [aPath moveToPoint:center];

        [aPath addArcWithCenter:center
                         radius:radius
                     startAngle:startAngle
                       endAngle:endAngle
                      clockwise:YES];

        [_clusteringManager.slicesArray addObject:slice];
        [_containerLayer addSublayer:slice];
      }];
}

- (CATextLayer *)constructTextLayerAtPoint:(CGPoint)point
                                WithString:(NSString *)string {
  CATextLayer *textLayer = [CATextLayer layer];
  [textLayer setFontSize:12];

  [textLayer setForegroundColor:[[UIColor blackColor] CGColor]];

  [textLayer setBounds:self.bounds];
  [textLayer setPosition:point];
  [textLayer setString:string];
  [textLayer setName:@"textLayer"];
  return textLayer;
}

- (void)doInitialSetup {
  _containerLayer = [CALayer layer];
  [self.layer addSublayer:_containerLayer];
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self doInitialSetup];
  }

  return self;
}

// TODO:check why I need this
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self doInitialSetup];
  }

  return self;
}

- (void)calculatePieChartSegmentSizes {

  _segmentsArray = [NSMutableArray new];

  NSUInteger numOfAnnotationsOfTypeA = 0;
  NSUInteger numOfAnnotationsOfTypeB = 0;
  NSUInteger numOfAnnotationsOfTypeC = 0;
  NSUInteger numOfAnnotationsOfTypeD = 0;
  NSUInteger numOfAnnotationsOfTypeE = 0;

  for (FBAnnotationCluster *annotation in self.annotation.annotations) {

    switch (annotation.type) {

    case typeA:
      numOfAnnotationsOfTypeA++;
      break;

    case typeB:
      numOfAnnotationsOfTypeB++;
      break;

    case typeC:
      numOfAnnotationsOfTypeC++;
      break;

    case typeD:
      numOfAnnotationsOfTypeD++;
      break;

    case typeE:
      numOfAnnotationsOfTypeE++;
      break;
    }
  }

  NSUInteger total = numOfAnnotationsOfTypeA + numOfAnnotationsOfTypeB +
                     numOfAnnotationsOfTypeC + numOfAnnotationsOfTypeD +
                     numOfAnnotationsOfTypeE;

  NSNumber *nsNumberOfAnnotationsOfTypeA =
      [NSNumber numberWithUnsignedInteger:numOfAnnotationsOfTypeA];

  NSNumber *nsNumberOfAnnotationsOfTypeB =
      [NSNumber numberWithUnsignedInteger:numOfAnnotationsOfTypeB];

  NSNumber *nsNumberOfAnnotationsOfTypeC =
      [NSNumber numberWithUnsignedInteger:numOfAnnotationsOfTypeC];

  NSNumber *nsNumberOfAnnotationsOfTypeD =
      [NSNumber numberWithUnsignedInteger:numOfAnnotationsOfTypeD];

  NSNumber *nsNumberOfAnnotationsOfTypeE =
      [NSNumber numberWithUnsignedInteger:numOfAnnotationsOfTypeE];

  NSArray *numOfAnnotationsByRating =
      [[NSArray alloc] initWithObjects:nsNumberOfAnnotationsOfTypeA,
                                       nsNumberOfAnnotationsOfTypeB,
                                       nsNumberOfAnnotationsOfTypeC,
                                       nsNumberOfAnnotationsOfTypeD,
                                       nsNumberOfAnnotationsOfTypeE, nil];

  [numOfAnnotationsByRating
      enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        NSNumber *numberOfAnnotationsInSegment = (NSNumber *)obj;

        NSNumber *type = [NSNumber numberWithUnsignedInteger:idx];

        double segmentSizeDouble =
            (double)numberOfAnnotationsInSegment.integerValue / total;

        NSNumber *segmentSize = [NSNumber numberWithFloat:segmentSizeDouble];

        NSDictionary *segmentProperties = [[NSDictionary alloc]
            initWithObjectsAndKeys:type, @"type", segmentSize, @"size",
                                   numberOfAnnotationsInSegment,
                                   @"annotationsCount", @0, @"startAngle", @0,
                                   @"endAngle", nil];

        [_segmentsArray addObject:segmentProperties];
      }];
}

- (UIImage *)grabImage {

  UIGraphicsBeginImageContext([self bounds].size);

  [[self layer] renderInContext:UIGraphicsGetCurrentContext()];

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return image;
}

- (UIImage *)drawPieChartImageInRect:(CGRect)rect {

  UIGraphicsBeginImageContext(rect.size);

  NSArray *coloursArray =
      [[NSArray alloc] initWithObjects:_clusteringManager.typeAColour,
                                       _clusteringManager.typeBColour,
                                       _clusteringManager.typeCColour,
                                       _clusteringManager.typeDColour,
                                       _clusteringManager.typeEColour,
                                       _clusteringManager.strokeColour, nil];

  CGRect circleRect = CGRectInset(self.bounds, 1, 1);

  CGPoint center =
      CGPointMake(CGRectGetMidX(circleRect), CGRectGetMidY(circleRect));

  [self calculatePieChartSegmentSizes];

  __block CGFloat previousSegmentAngle;
  __block CGFloat currentPointOnArcX;
  __block CGFloat currentPointOnArcY;

  [_segmentsArray
      enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        UIBezierPath *aPath = [UIBezierPath bezierPath];
        NSMutableDictionary *segment = [obj mutableCopy];

        NSNumber *segmentType = segment[@"type"];

        UIColor *color = coloursArray[segmentType.unsignedIntegerValue];

        NSNumber *segmentSize = segment[@"size"];
        double segmentSizeDouble = segmentSize.doubleValue;

        CGFloat startAngle = 0;
        CGFloat endAngle = 0;

        if (idx == 0) {
          startAngle = 0;
        } else if (previousSegmentAngle) {

          startAngle = previousSegmentAngle;
        }

        if (idx == _segmentsArray.count - 1) {
          endAngle = 2 * M_PI;
          previousSegmentAngle = 0;
          currentPointOnArcX = 0;
          currentPointOnArcY = 0;
        } else {

          endAngle = 2 * M_PI * segmentSizeDouble;
          previousSegmentAngle = endAngle;
        }

        [aPath moveToPoint:CGPointMake(center.x, center.y)];

        [aPath addArcWithCenter:center
                         radius:rect.size.width / 2
                     startAngle:startAngle
                       endAngle:endAngle
                      clockwise:YES];

        [aPath setLineWidth:3];
        [aPath closePath];
        [color setFill];
        [[_clusteringManager strokeColour] setStroke];
        [aPath stroke];
        [aPath fill];
      }];

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return image;
}

@end
