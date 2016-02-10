//
//  PieSliceLayer.h
//
//  Created by Oleksandr Bretsko on 12/25/15.
//  Copyright © 2015 Oleksandr Bretsko. All rights reserved.
//

@import UIKit;
@import QuartzCore;

@interface FBClusterViewSegment : CALayer

@property(nonatomic, assign) CGFloat startAngle;
@property(nonatomic, assign) CGFloat endAngle;
@property(nonatomic, assign) CGFloat startAngleAnimated;
@property(nonatomic, assign) CGFloat endAngleAnimated;

@property(nonatomic, strong) NSNumber *segmentSize;

@property(nonatomic, strong) UIColor *fillColor;
@property(nonatomic) CGFloat strokeWidth;
@property(nonatomic, strong) UIColor *strokeColor;

@end
