//
//  SKDress.m
//  PromApp
//
//  Created by Scott Krulcik on 7/1/14.
//  Copyright (c) 2014 Scott Krulcik. All rights reserved.
//

#import "SKDress.h"
#import <Parse/PFObject+Subclass.h>

@implementation SKDress

@dynamic owner;
@dynamic store;
@dynamic designer;
@dynamic styleNumber;
@dynamic dressColor;
@dynamic image;

+ (NSString *)parseClassName
{
    return @"Dress";
}

/*- (id)init
{
    return [super initWithClassName:self.parseClassName];
}

- (id)initWithDesigner:(NSString *)designerName styleNumber:(NSString *)styleID color:(NSString *)color
{
    self = [super initWithClassName:];
    if(self){
        self.owner = nil;
        self.store = nil;
        self.designer = designerName;
        self.styleNumber = styleID;
        self.dressColor = color;
//        self.image = [[UIImage alloc] init];
    }
    return self;
}*/

@end
