//
//  SKAddDressViewController.m
//  PromApp
//
//  Created by Scott Krulcik on 7/1/14.
//  Copyright (c) 2014 Scott Krulcik. All rights reserved.
//

#import "SKAddDressViewController.h"
#import "SKImageEditorCell.h"
#import "SKMainTabViewController.h"
#import "SKPromQueryController.h"
#import "SKStore.h"
#import "SKStringEntryCell.h"



@interface SKAddDressViewController ()
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) NSMutableArray *capturedImages;
@property (weak, nonatomic) IBOutlet UINavigationItem *navTitle;

@end

@implementation SKAddDressViewController{
    BOOL _isNewDress;       //So we know whether we are creating or editing
    BOOL _imageChanged;     //No need to take up bandwith with images if they aren't changed
    BOOL _promChanged;      //Stores if the prom has been changed
    NSMutableDictionary *dressData;
}
@synthesize cancelButton;
@synthesize doneButton;
@synthesize dressImageView;
//@synthesize tableView;

static NSArray *keyForRowIndex;
static NSDictionary *readableNames;

- (void) setupForCreation{
    //self = [self initForDress:[[SKDress alloc] init]];
    [self setupWithDress:[[SKDress alloc] init]];
    _isNewDress = YES;
}

- (void) setupWithDress:(SKDress *)dressObject
{
    //self = [super initWithNibName:@"EditDress" bundle:nil];
    if([[PFUser currentUser] isMemberOfClass:[SKStore class]]){
        keyForRowIndex = @[@"image", @"designer", @"styleNumber", @"dressColor", @"prom", @"owner"];
    }else{
        keyForRowIndex = @[@"image", @"designer", @"styleNumber", @"dressColor", @"prom", @"store"];
    }
    if(!readableNames){
        readableNames = @{@"image":@"Dress Image",
                          @"designer":@"Designer",
                          @"styleNumber":@"Style ID Number",
                          @"dressColor":@"Color",
                          @"owner":@"Dress Owner",
                          @"store":@"Store",
                          @"prom":@"Prom"};
    }
    _imageChanged = NO;
    _promChanged = NO;
    dressData = [[NSMutableDictionary alloc] init];
    self.dress = dressObject;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    _isNewDress = YES;
    [self setupForCreation];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.capturedImages = [[NSMutableArray alloc] init];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"StringEntryCell" bundle:nil] forCellReuseIdentifier:@"StringEntry"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ImageEditorCell" bundle:nil] forCellReuseIdentifier:@"ImageEditor"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showImagePickerForCamera:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
}


- (IBAction)showImagePickerForPhotoPicker:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}


- (IBAction)savePressed:(id)sender {
    [self saveDress:self.dress withCompletion:^(void){
        [self performSegueWithIdentifier:@"SaveDress" sender:self];
    }];
}


- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if (self.dressImageView.isAnimating)
    {
        [self.dressImageView stopAnimating];
    }
    
    if (self.capturedImages.count > 0)
    {
        [self.capturedImages removeAllObjects];
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)addImage:(id)sender
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [self showImagePickerForPhotoPicker:sender];
    } else {
        [self showImagePickerForCamera:sender];
    }
}

- (void) performPromAssociation:(SKProm *) prom
{
    [dressData setObject:prom forKey:@"prom"];
    _promChanged = YES;
    NSArray *cells = [self.tableView visibleCells];
    for (int i=0; i<[cells count]; i++){
        if([@"prom" isEqualToString:[SKAddDressViewController keyForRowIndex:i]]){
            //Is prom cell
            SKStringEntryCell *pcell = cells[i];
            pcell.field.text = [dressData[@"prom"] schoolName];
        }
    }
}



typedef void(^voidCompletion)(void);
- (void) saveDress:(SKDress *)dress withCompletion:(voidCompletion)block
{
    NSArray *cells = [self.tableView visibleCells];
    for (int i=0; i<[cells count]; i++){
        if([@"image" isEqualToString:[SKAddDressViewController keyForRowIndex:i]]){
            //Is image cell
            SKImageEditorCell *imgCell = cells[i];
            UIImage *currentPic = imgCell.basicImage.image;
            if(currentPic){
                [dressData setObject:currentPic forKey:[SKAddDressViewController keyForRowIndex:i]];
            }
        }else if(![@"prom" isEqualToString:[SKAddDressViewController keyForRowIndex:i]] || _promChanged){
            //Is text entry cell
            SKStringEntryCell *txtCell = cells[i];
            NSString *val = txtCell.field.text;
            if([val isEqualToString:@""] || val == nil){
                val = [dress objectForKey:[SKAddDressViewController keyForRowIndex:i]];
            }
            if(val)
                [dressData setObject:val forKey:[SKAddDressViewController keyForRowIndex:i]];
        }
    }
    if(dressData[@"designer"] != nil && dressData[@"styleNumber"] != nil){
        PFUser *current = [PFUser currentUser];
        for(NSString *key in dressData){
            if(dressData[key]){
                if(![key isEqualToString:@"image"]){
                    //don't save the image until the end, other data is used for filename
                    [dress setObject:dressData[key] forKey:key];
                }
            }
        }
        if(_imageChanged){
            //Save Image of dress as PFFile
            NSData *imageData = UIImagePNGRepresentation(self.dressImageView.image);
            NSString *filename = [NSString stringWithFormat:@"%@%@Picture.png",dress.designer, dress.styleNumber];
            PFFile *imageFile = [PFFile fileWithName:filename data:imageData];
            dress.image = imageFile;
        }
        self.dress.owner = current;
        [self.dress saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (succeeded){
                NSLog(@"Succeeded in saving %@ dress with ID %@.", dress.designer, dress.objectId);
                [current addObject:dress.objectId forKey:@"dressIDs"];
                [current saveInBackground];
                block();
            } else {
                NSLog(@"Failed in saving %@ dress for reason: %@", dress.designer, error);
                UIAlertView *fail = [[UIAlertView alloc] initWithTitle:@"Internal Error" message:@"We are sorry, your changes could not be saved." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
                [fail show];
            }
        }];
    }else{
        UIAlertView *fail = [[UIAlertView alloc] initWithTitle:@"Missing Required Fields" message:@"You must enter a designer and style number." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [fail show];
    }
}

- (void)populateImage
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([self.capturedImages count] > 0)
    {
        if ([self.capturedImages count] == 1)
        {
            // Camera took a single picture.
            self.dressImageView.image = [self.capturedImages objectAtIndex:0];
            NSLog(@"%@", self.dressImageView);
        }
        else
        {
            // Camera took multiple pictures; use the list of images for animation.
            self.dressImageView.animationImages = self.capturedImages;
            self.dressImageView.animationDuration = 5.0;    // Show each captured photo for 5 seconds.
            self.dressImageView.animationRepeatCount = 0;   // Animate forever (show all photos).
            [self.dressImageView startAnimating];
        }
        
        // To be ready to start again, clear the captured images array.
        [self.capturedImages removeAllObjects];
    }
    
    self.imagePickerController = nil;
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSLog(@"finished picking media");
    [self.capturedImages addObject:image];
    [self populateImage];
    _imageChanged = YES;
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"Picker cancelled");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [keyForRowIndex count];//How many keys (and corresponding editable properties) are there
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[SKAddDressViewController keyForRowIndex:[indexPath row]] isEqualToString:@"prom"]){
        [self performSegueWithIdentifier:@"SelectProm" sender:self];
    }
}

- (UITableViewCell*) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [SKAddDressViewController keyForRowIndex:[indexPath row]];
    NSLog(@"Tried creating cell for key %@", key);
    
    if([key isEqualToString:@"image"]){
        SKImageEditorCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ImageEditor"];
        if (cell == nil){
            cell = [[SKImageEditorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ImageEditor" ];
        }
        [cell.editButton addTarget:self action:@selector(addImage:) forControlEvents:UIControlEventTouchUpInside];
        cell.key = key;
        cell.basicImage.image = [UIImage imageNamed:@"EmptyDress"];
        if(!_isNewDress){
            [(PFImageView *)cell.pfimage setFile:self.dress.image]; //placeholder (should already be there anyways)
            [(PFImageView *)cell.pfimage loadInBackground]; //Loads existing image from Parse
        }
        return cell;
    }else{
        SKStringEntryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"StringEntry"];
        if (cell == nil){
            cell = [[SKStringEntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StringEntry" ];
        }
        cell.field.delegate = self;
        cell.key = key;
        NSString *currentVal = [self.dress objectForKey:key];
        if(!_isNewDress && ![currentVal isEqualToString:@""]){
            if([key isEqualToString:@"prom"]){
                cell.field.text = [[self.dress objectForKey:key] schoolName];
            }else{;
                cell.field.text =[self.dress objectForKey:key];
            }
        }else{
            cell.field.text = @"";
            cell.field.placeholder = [SKAddDressViewController readableNameForKey:key];
        }
        if([key isEqualToString:@"prom"]){
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.field.enabled = NO;
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row]==0){
        //Is image editing cell
        return 200;
    }else{
        return 43;
    }
}

#pragma mark - Getters and Setters

- (UIImageView *) dressImageView
{
    SKImageEditorCell *cell = [self.tableView visibleCells][0];
    return [cell basicImage];
}

#pragma mark - Statics
+(NSString *)readableNameForKey:(NSString *)key{
    return readableNames[key];
}
+(NSString *)keyForRowIndex:(long)num{
    return keyForRowIndex[num];
}


#pragma mark - Navigation
- (IBAction) unwindFromSelectProm:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[SKPromQueryController class]]) {
        SKPromQueryController *promController = segue.sourceViewController;
        // if the user clicked Cancel, we don't want to change the color
        if (promController.selectedProm) {
            [self performPromAssociation:promController.selectedProm];
        }
    }
}

- (IBAction) unwindFromSelectPromCancel:(UIStoryboardSegue *)segue
{
}
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
 */


@end
