//
//  SKImageEditorCell.m
//  PromApp
//
//  Created by Scott Krulcik on 8/3/14.
//  Copyright (c) 2014 Scott Krulcik. All rights reserved.
//

#import "SKImageEditorCell.h"

@implementation SKImageEditorCell
@synthesize key;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.pfimage = (PFImageView *)self.basicImage;
        
    }
    return self;
}

- (void)awakeFromNib
{
    //self.imageView = (PFImageView *)self.basicImage;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end