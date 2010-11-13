//
//  EnemyAnnotationView.m
//  RunQuest
//
//  Created by Joe Walsh on 9/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EnemyAnnotationView.h"
#import "EnemyAnnotationLayer.h"
#import "EnemyMapSpawn.h";

#define NON_PULSING_RADIUS 12.0f
#define PULSING_RADIUS 42.0f

@implementation EnemyAnnotationView
@synthesize pulsing;

+ (Class)layerClass { 
	return [EnemyAnnotationLayer class];
}

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
	if (( self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier] )) {
		self.draggable = NO;
		self.canShowCallout = NO;
		self.bounds = CGRectMake(0, 0, NON_PULSING_RADIUS, NON_PULSING_RADIUS);
		self.opaque = NO;
		self.pulsing = NO;
		self.layer.opacity = 1.0f;
	} return self;
}

- (void)setPulsing:(BOOL)shouldPulse {
	if ( !self.isPulsing && shouldPulse ) {
		self.layer.opacity = 0;
		CABasicAnimation* grow = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
		grow.fromValue = [NSNumber numberWithDouble:0];
		grow.toValue = [NSNumber numberWithDouble:1];
		grow.duration = .75;
		
		CABasicAnimation* fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fade.fromValue = [NSNumber numberWithDouble:1];
		fade.toValue = [NSNumber numberWithDouble:0];
		fade.duration = .75;
		
		CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		fade.timingFunction = timingFunction;
		grow.timingFunction = timingFunction;
		
		CAAnimationGroup *pulse = [CAAnimationGroup animation];
		pulse.animations = [NSArray arrayWithObjects:grow, fade, nil];
		pulse.repeatCount = CGFLOAT_MAX;
		pulse.duration = 1.0;
		
		[self.layer addAnimation:pulse forKey:@"pulse"];
	}
	else if ( self.isPulsing && !shouldPulse ) {
		[self.layer removeAllAnimations];
		self.layer.opacity = 1;
		self.layer.transform = CATransform3DMakeScale(.25,.25,1);
	}
	
	pulsing = shouldPulse;
}

- (void)pulse {
	self.layer.opacity = 0.0f;
	self.bounds = CGRectMake(0, 0, PULSING_RADIUS, PULSING_RADIUS);
	CABasicAnimation* grow = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	grow.fromValue = [NSNumber numberWithDouble:0];
	grow.toValue = [NSNumber numberWithDouble:1];
	grow.duration = .75;
	
	CABasicAnimation* fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fade.fromValue = [NSNumber numberWithDouble:1];
	fade.toValue = [NSNumber numberWithDouble:0];
	fade.duration = .75;
	
	CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	fade.timingFunction = timingFunction;
	grow.timingFunction = timingFunction;
	
	CAAnimationGroup *pulse = [CAAnimationGroup animation];
	pulse.animations = [NSArray arrayWithObjects:grow, fade, nil];
	pulse.repeatCount = 1;
	pulse.duration = 1.5;
	
	[self.layer addAnimation:pulse forKey:@"pulse"];
}

- (void)stopPulsing {
	self.bounds = CGRectMake(0, 0, NON_PULSING_RADIUS, NON_PULSING_RADIUS);
	self.layer.opacity = 1.0f;
}

- (void)drawRect:(CGRect)rect {
	//CGContextRef context = UIGraphicsGetCurrentContext();
	//[self.layer drawInContext:context];
	[super drawRect:rect];
}


@end
