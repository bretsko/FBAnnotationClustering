//
//  PieSliceLayer.m
//  lv-165IOS
//
//  Created by Oleksandr Bretsko on 12/25/15.
//  Copyright © 2015 SS. All rights reserved.
//

#import "FBClusterViewSegment.h"
#import "FBClusteringManager.h"

@implementation FBClusterViewSegment

@dynamic startAngle, endAngle;

- (id<CAAction>)actionForKey:(NSString *)event {

  if ([event isEqualToString:@"endAngle"]) {
    CABasicAnimation *endAngleAnimation =
        [CABasicAnimation animationWithKeyPath:@"endAngle"];

    endAngleAnimation.toValue = @(self.endAngle);
    endAngleAnimation.fillMode = kCAFillModeForwards;
    endAngleAnimation.removedOnCompletion = NO;
    endAngleAnimation.duration = 1.0;
    return endAngleAnimation;
  }

  return [super actionForKey:event];
}

- (id)initWithLayer:(id)layer {

  if (self = [super initWithLayer:layer]) {
    if ([layer isKindOfClass:[FBClusterViewSegment class]]) {
      FBClusterViewSegment *other = (FBClusterViewSegment *)layer;
      self.startAngle = other.startAngle;
      self.endAngle = other.endAngle;
      self.fillColor = other.fillColor;
      self.strokeColor = other.strokeColor;
      self.strokeWidth = other.strokeWidth;
    }
  }

  return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {

  if ([key isEqualToString:@"endAngle"]) {

    return YES;
  }

  return [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)ctx {

  CGPoint center =
      CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
  CGFloat radius = MIN(center.x, center.y);

  CGContextBeginPath(ctx);
  CGContextMoveToPoint(ctx, center.x, center.y);

  CGPoint point = CGPointMake(center.x + radius * cosf(self.startAngle),
                              center.y + radius * sinf(self.startAngle));
  CGContextAddLineToPoint(ctx, point.x, point.y);

  int clockwise = self.startAngle < self.endAngle;
  CGContextAddArc(ctx, center.x, center.y, radius, self.startAngle,
                  self.endAngle, clockwise);

  CGContextClosePath(ctx);

  CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);
  CGContextSetStrokeColorWithColor(ctx, self.strokeColor.CGColor);
  CGContextSetLineWidth(ctx, self.strokeWidth);

  CGContextDrawPath(ctx, kCGPathFillStroke);
}

@end
