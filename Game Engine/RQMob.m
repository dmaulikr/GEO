#import "RQMob.h"

@implementation RQMob

- (id)init
{
	if (self = [super init]) {
		staminaRegenRate = 1.75;
		secondsLeftOfPhysicalShields = 0;
		secondsLeftOfMagicalShields = 0;
	}
	return self;
}

- (void)dealloc
{
	[name release]; name = nil;
	[super dealloc]; 
}

@synthesize name;

- (NSInteger)currentHP {
    return currentHP;
}

- (void)setCurrentHP:(NSInteger)value {
	currentHP = value;
	if (currentHP > maxHP) {
		currentHP = maxHP;
	}
	if (currentHP < 0) {
		currentHP = 0;
	}
}

@synthesize maxHP;
@synthesize level;

- (NSInteger)stamina {
    return stamina;
}

- (void)setStamina:(NSInteger)value {
	stamina = value;
	if (stamina > 100) {
		stamina = 100;
	}
	if (stamina < 0) {
		stamina = 0;
	}
}

@synthesize staminaRegenRate;
@synthesize secondsLeftOfPhysicalShields;
@synthesize secondsLeftOfMagicalShields;

- (NSInteger)randomAttackValueAgainstMob:(RQMob *)mob
{
	// generate a random value to represnt an attack form self against mob
	// TODO: More interesting math
	return 5;
}

- (NSInteger)randomStrongAttackValueAgainstMob:(RQMob *)mob
{
	// generate a random value to represnt an attack form self against mob
	// TODO: More interesting math
	return [self randomAttackValueAgainstMob:mob]*2;
}

@end
