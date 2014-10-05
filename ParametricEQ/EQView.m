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

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
    
}


- (void)drawRect:(CGRect)rect
{
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    [self drawBackgroundInRect:rect inContext:context withColorSpace:colorSpace];

    [self drawFilterCurveInRect:rect inContext:context withColorSpace:colorSpace];
    [self drawAxesInRect:rect inContext:context withColorSpace:colorSpace];

    
    CGColorSpaceRelease(colorSpace);
}

-(void) drawBackgroundInRect: (CGRect)rect inContext: (CGContextRef)context withColorSpace: (CGColorSpaceRef)colorSpace
{
    
    // thanks to http://www.raywenderlich.com/34003/core-graphics-tutorial-curves-and-layers
    
    // NI Colors
//    UIColor * farStop = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
//    UIColor * middleStop = [UIColor colorWithRed:78.0/255.0 green:99.0/255.0 blue:112.0/255.0 alpha:1.0];
//    UIColor * baseColor = [UIColor colorWithRed:93.0/255.0 green:134.0/255.0 blue:160.0/255.0 alpha:1.0];

    //Draw nice three-step gradient in the back of the EQView (draw this first!)
    // GreyScale colors
    UIColor * farStop = [UIColor colorWithWhite:0.2 alpha:1.0];
    UIColor * middleStop = [UIColor colorWithWhite:0.4 alpha:1.0];
    UIColor * baseColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    
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
    
    // Remove UILabels id any
    for (UIView *subView in self.subviews)
    {
        if ([subView isKindOfClass:[UILabel class]])
        {
            [subView removeFromSuperview];
        }
    }
    
    
    CGContextSaveGState(context);
    
    
    _normLineY = rect.size.height*(fabs(PARQ_MAX_GAIN)/(fabs(PARQ_MAX_GAIN)+fabs(PARQ_MIN_GAIN)));

    
    // ------------------
    // Draw the norm line
    // ------------------
    UIBezierPath *normLine = [UIBezierPath bezierPath];
    
    [normLine moveToPoint:CGPointMake(-5.0f, _normLineY)];
    [normLine addLineToPoint:CGPointMake(rect.size.width+5.0f, _normLineY)];
    
    [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2] setStroke];
    normLine.lineWidth = 3.0f;
    [normLine stroke];
    
    
    // ------------------
    // Draw the filter curve (curve fitting: Catmull-Rom)
    // ------------------
    UIBezierPath *aPath = [self smoothedPathWithGranularity:20 andPoints:_points inRect:rect];

    // Set the render colors.
    [[UIColor whiteColor] setStroke];
    [[UIColor colorWithRed:111.0/255.0 green:0.0 blue:1.0 alpha:0.2] setFill];
    
    // Adjust the drawing options as needed.
    aPath.lineWidth = 3.0f;
    
    // Fill the path before stroking it so that the fill
    // color does not obscure the stroked line.
    [aPath fill];
    [aPath stroke];
    
    // ------------------
    // Draw vertical lines
    // ------------------
    for (int i = 0; i < [_points count]; i++) {
        UIBezierPath *debugLine = [UIBezierPath bezierPath];
        CGFloat xVal = [[_points objectAtIndex:i] CGPointValue].x;

        [debugLine moveToPoint:CGPointMake(xVal, -5.0f)];
        [debugLine addLineToPoint:CGPointMake(xVal, rect.size.height + 5.0f)];
        
        [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2] setStroke];
        debugLine.lineWidth = 1.0f;
        [debugLine stroke];
    }

    if(!CGContextIsPathEmpty(context)) {
        CGContextClip(context);
    }
    
    CGContextRestoreGState(context);
    
}

-(void)drawAxesInRect: (CGRect)rect inContext: (CGContextRef)context withColorSpace: (CGColorSpaceRef)colorSpace {
    CGContextSaveGState(context);
    
    // ------------------
    // Axes
    // ------------------
    
    // X AXIS
    UIBezierPath *xAxis = [UIBezierPath bezierPath];
    
    static CGFloat refY = rect.size.height-PARQ_MARGIN_Y;
    static CGFloat refHighY = refY-8.0f;
    
    CGFloat tickX;
    CGFloat noOfLogTicks = log10f(PARQ_MAX_F0/PARQ_MIN_F0)/log10f(10);
    
    [xAxis moveToPoint:CGPointMake(PARQ_MARGIN_X, refHighY)];
    [xAxis addLineToPoint:CGPointMake(PARQ_MARGIN_X, refY)];
    
    for (int i = 0; i < noOfLogTicks; i++) {
        
        // Ticks
        if (i<=noOfLogTicks) {
            tickX = (((float)i)/floorf(noOfLogTicks)); // equal spacing
            tickX *= (rect.size.width-2*PARQ_MARGIN_X); // Scaling
            tickX += PARQ_MARGIN_X; // Margin
            
        } else {
            tickX = rect.size.width-PARQ_MARGIN_X;
            
        }
        [xAxis addLineToPoint:CGPointMake(tickX, refY)];
        [xAxis addLineToPoint:CGPointMake(tickX, refHighY)];
        [xAxis moveToPoint:CGPointMake(tickX, refY)];
        
        // Tick Labels
        CGFloat labelWidth = 30.0f;
        CGFloat labelHeight = 15.0f;
        CGFloat labelX = tickX-labelWidth/2;
        CGFloat labelY = refY-labelHeight-5.0f;
        CGRect labelRect = CGRectMake(labelX, labelY, labelWidth, labelHeight);
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        if (i<=noOfLogTicks) {
            [label setText:[NSString stringWithFormat:@"%.0f", 2*pow(10, i+1)]]; // Label texts
        } else {
            [label setText:[NSString stringWithFormat:@"%.0f", PARQ_MAX_F0]];
        }
        label.adjustsFontSizeToFitWidth = NO;
        [label setFont:[UIFont fontWithName:@"Helvetica" size:10]];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        // set alignment based on position
        if (i == 0) {
            [label setTextAlignment:NSTextAlignmentLeft];
            [label setFrame:CGRectMake(labelX+labelWidth/2, labelY, labelWidth, labelHeight)];
        } else if (i >= ((int)noOfLogTicks)) {
            [label setTextAlignment:NSTextAlignmentRight];
            [label setFrame:CGRectMake(labelX-labelWidth/2, labelY, labelWidth, labelHeight)];
        } else {
            [label setTextAlignment:NSTextAlignmentCenter];
        }
        [self addSubview:label];
    }
    
    // Setup stroke.
    [[UIColor whiteColor] setStroke];
    xAxis.lineWidth = 1.0f;
    [xAxis stroke];
    
    
    // Y AXIS
    UIBezierPath *yAxis = [UIBezierPath bezierPath];
    
    
    static CGFloat refX = 4.0f;
    static CGFloat refHighX = refX+4.0f;
    
    CGFloat tickY;
    
    CGFloat noOfYTicks = (fabsf(PARQ_MAX_GAIN)+fabsf(PARQ_MIN_GAIN))/6.0f;
    
    [yAxis moveToPoint:CGPointMake(refHighX, PARQ_MARGIN_Y)];
    [yAxis addLineToPoint:CGPointMake(refX, PARQ_MARGIN_Y)];
    
    for (int i = 0; i < noOfYTicks; i++) {
        
        // Ticks
        tickY = PARQ_MARGIN_Y+((rect.size.height-2*PARQ_MARGIN_Y)*(((float)i)/noOfYTicks));
        [yAxis addLineToPoint:CGPointMake(refX, tickY)];
        [yAxis addLineToPoint:CGPointMake(refHighX, tickY)];
        [yAxis moveToPoint:CGPointMake(refX, tickY)];
        
        // Tick Labels
        
        CGFloat labelWidth = 30.0f;
        CGFloat labelHeight = 15.0f;
        CGFloat labelY = tickY-labelHeight/2;
        CGFloat labelX = refX+10.0f;
        CGRect labelRect = CGRectMake(labelX, labelY, labelWidth, labelHeight);
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        [label setText:[NSString stringWithFormat:@"%.0f", PARQ_MAX_GAIN-(i*6.0f)]];
        label.adjustsFontSizeToFitWidth = NO;
        [label setFont:[UIFont fontWithName:@"Helvetica" size:10]];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [label setTextAlignment:NSTextAlignmentLeft];
        // set alignment based on position
        if (i == 0) {
            [label setFrame:CGRectMake(labelX, labelY+labelHeight/2-4.0f, labelWidth, labelHeight)];
        } else if (i == noOfYTicks) {
            [label setFrame:CGRectMake(labelX, labelY-labelHeight/2, labelWidth, labelHeight)];
        }
        [self addSubview:label];
    }
    
    // Setup stroke.
    [[UIColor whiteColor] setStroke];
    yAxis.lineWidth = 1.0f;
    [yAxis stroke];

    if(!CGContextIsPathEmpty(context)) {
        CGContextClip(context);
    }
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
