//
//  EQView.m
//  ParametricEQ
//
//  Created by Julian Vogels on 25/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "EQView.h"

#define VALUE(_INDEX_) [NSValue valueWithCGPoint:points[_INDEX_]]
#define POINT(_INDEX_) [(NSValue *)[points objectAtIndex:_INDEX_] CGPointValue]


@implementation EQView

- (id)initWithFrame:(CGRect)frame andCenterFrequency:(float)freq andGain:(float)gain andQ:(float)qfactor
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        
    }
    return self;
    
}

-(void)adjustGraph{
    
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    [self drawBackgroundInRect:rect inContext:context withColorSpace:colorSpace];
    [self drawFilterCurveInRect:rect inContext:context withColorSpace:colorSpace];
    
    
    CGColorSpaceRelease(colorSpace);
}

-(void) drawBackgroundInRect: (CGRect)rect inContext: (CGContextRef)context withColorSpace: (CGColorSpaceRef)colorSpace
{
    
    //Draw nice three-step gradient in the back of the EQView (draw this first!)
    UIColor * farStop = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
    UIColor * middleStop = [UIColor colorWithRed:78.0/255.0 green:99.0/255.0 blue:112.0/255.0 alpha:1.0];
    UIColor * baseColor = [UIColor colorWithRed:93.0/255.0 green:134.0/255.0 blue:160.0/255.0 alpha:1.0];
    
    CGContextSaveGState(context);
    NSArray * gradientColors = @[(__bridge id)baseColor.CGColor, (__bridge id)middleStop.CGColor, (__bridge id)farStop.CGColor];
    CGFloat locations[] = { 0.0, 0.5, 0.8 };
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) gradientColors, locations);
    
    CGPoint startPoint = CGPointMake(rect.size.height / 2, 0);
    CGPoint endPoint = CGPointMake(rect.size.height / 2, rect.size.width);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
}

-(void) drawFilterCurveInRect: (CGRect)rect inContext: (CGContextRef)context withColorSpace: (CGColorSpaceRef)colorSpace
{
    
    CGContextSaveGState(context);
    
    _normLineY = rect.size.height*(fabs(PARQ_MAX_GAIN)/(fabs(PARQ_MAX_GAIN)+fabs(PARQ_MIN_GAIN)));


//    CGContextSetLineWidth(context, 2.0f);
    
        // Draw the filter curve (no curve fitting)
//    CGMutablePathRef filterCurve = CGPathCreateMutable();
//    CGPathMoveToPoint(filterCurve, nil, -5, normLineY);
//    
//   
//    CGPoint point;
    
//    if (_points != nil) {
//        for (int i = 0; i < _points.count; i++) {
//            point = [[_points objectAtIndex:i] CGPointValue];
//            
//            CGPathAddLineToPoint(filterCurve, nil, point.x, point.y);
//        }
//    }
    
//    CGPathAddLineToPoint(filterCurve, nil, rect.size.width, normLineY);
//    CGPathAddLineToPoint(filterCurve, nil, 580, rect.size.width);
//    CGPathAddLineToPoint(filterCurve, nil, -5, rect.size.width);
//    
//    CGPathCloseSubpath(filterCurve);
    
    // ------------------
    // Draw the norm line
    // ------------------
    UIBezierPath *normLine = [UIBezierPath bezierPath];
    
    [normLine moveToPoint:CGPointMake(-5.0f, _normLineY)];
    [normLine addLineToPoint:CGPointMake(rect.size.width+5.0f, _normLineY)];
    
    // Set the render colors.
    [[UIColor colorWithRed:111.0/255.0 green:0.0 blue:1.0 alpha:0.2] setStroke];
    
    // Adjust the drawing options as needed.
    normLine.lineWidth = 1.0f;
    
    // Fill the path before stroking it so that the fill
    // color does not obscure the stroked line.
    [normLine stroke];
    
    
    // ------------------
    // Draw the filter curve (curve fitting: Catmull-Rom)
    // ------------------
    UIBezierPath *aPath = [self smoothedPathWithGranularity:20 andPoints:_points inRect:rect];

    // Set the render colors.
    [[UIColor whiteColor] setStroke];
    [[UIColor colorWithRed:111.0/255.0 green:0.0 blue:1.0 alpha:0.2] setFill];
    
    // Adjust the drawing options as needed.
    aPath.lineWidth = 3;
    
    // Fill the path before stroking it so that the fill
    // color does not obscure the stroked line.
    [aPath fill];
    [aPath stroke];
    
    
    // ------------------
    // Axes
    // ------------------
    CGFloat marginY = 4.0f;
    CGFloat marginX = 5.0f;
    CGFloat refY = rect.size.height-marginY;
    CGFloat refHighY = refY-8.0f;
    
    CGFloat tickX;
    
    // somethings wrong here
//    CGFloat noOfLogTicks = (logf((PARQ_MAX_F0*2.0L*M_PI)/44100.0L)-logf((PARQ_MIN_F0*2.0L*M_PI)/44100.0L))/logf(10);

    CGFloat noOfLogTicks = (PARQ_MAX_F0-PARQ_MIN_F0)/1000.0f;

    UIBezierPath *xAxis = [UIBezierPath bezierPath];
    
    [xAxis moveToPoint:CGPointMake(marginX, refHighY)];
    [xAxis addLineToPoint:CGPointMake(marginX, refY)];
    
    for (int i = 0; i < noOfLogTicks; i++) {
        tickX = (float)(i*((PARQ_MAX_F0-PARQ_MIN_F0)/noOfLogTicks))/(PARQ_MAX_F0-PARQ_MIN_F0)*rect.size.width+marginX;
        [xAxis addLineToPoint:CGPointMake(tickX, refY)];
        [xAxis addLineToPoint:CGPointMake(tickX, refHighY)];
        [xAxis moveToPoint:CGPointMake(tickX, refY)];
        
//        NSLog(@"x ticks i: %d atpos: %f range: %f noOfLogTicks: %f", i, tickX, PARQ_MAX_F0-PARQ_MIN_F0, noOfLogTicks);
    }
    
    // Set the render colors.
    [[UIColor whiteColor] setStroke];
    
    // Adjust the drawing options as needed.
    xAxis.lineWidth = 1.0f;
    
    // Fill the path before stroking it so that the fill
    // color does not obscure the stroked line.
    [xAxis stroke];
    
    // Background Drawing
    
//    CGContextAddPath(context, filterCurve);
    CGContextClip(context);
    CGContextSetLineWidth(context, 8);
    
    // Cleanup Code
//    CGPathRelease(filterCurve);
    CGContextRestoreGState(context);
    
}

// thanks to https://stackoverflow.com/questions/8702696/drawing-smooth-curves-methods-needed0

- (UIBezierPath*)smoothedPathWithGranularity:(NSInteger)granularity andPoints:(NSMutableArray *)points inRect:(CGRect)rect;
{
    // Add control points to make the math make sense
    [points insertObject:[NSValue valueWithCGPoint:CGPointMake(- 5.0f, [[points objectAtIndex:0] CGPointValue].y)] atIndex:0];
    [points addObject:[points lastObject]];
    
    UIBezierPath *smoothedPath = [UIBezierPath bezierPath];
    
    [smoothedPath moveToPoint:POINT(0)];
    
    for (NSUInteger index = 1; index < points.count - 2; index++)
    {
        CGPoint p0 = POINT(index - 1);
        CGPoint p1 = POINT(index);
        CGPoint p2 = POINT(index + 1);
        CGPoint p3 = POINT(index + 2);
        
        // now add n points starting at p1 + dx/dy up until p2 using Catmull-Rom splines
        for (int i = 1; i < granularity; i++)
        {
            float t = (float) i * (1.0f / (float) granularity);
            float tt = t * t;
            float ttt = tt * t;
            
            CGPoint pi; // intermediate point
            pi.x = 0.5 * (2*p1.x+(p2.x-p0.x)*t + (2*p0.x-5*p1.x+4*p2.x-p3.x)*tt + (3*p1.x-p0.x-3*p2.x+p3.x)*ttt);
            pi.y = 0.5 * (2*p1.y+(p2.y-p0.y)*t + (2*p0.y-5*p1.y+4*p2.y-p3.y)*tt + (3*p1.y-p0.y-3*p2.y+p3.y)*ttt);
            [smoothedPath addLineToPoint:pi];
        }
        
        // Now add p2
        [smoothedPath addLineToPoint:p2];
    }
    
    
    // finish by going round the bottom and closig the path
    [smoothedPath addLineToPoint:CGPointMake(rect.size.width + 5.0f, [[points lastObject] CGPointValue].y)];
    [smoothedPath addLineToPoint:CGPointMake(rect.size.width + 5.0f, rect.size.height + 5.0f)];
    [smoothedPath addLineToPoint:CGPointMake(- 5.0f, rect.size.height + 5.0f)];
    [smoothedPath closePath];
    
    return smoothedPath;
}
@end
