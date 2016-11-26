//
//  ViewController.m
//  SomeNEONTests
//
//  Created by Borna Noureddin on 2014-11-06.
//  Copyright (c) 2014 BCIT. All rights reserved.
//

#import "ViewController.h"
#import "arm_neon.h"

typedef enum { CODEGEN_CPP=0, CODEGEN_NEON_INT, CODEGEN_NEON_ASM } CodeGenType;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showImagePicker:(id)sender
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:NO completion:nil];
}




void convertToGrayscaleNEON_asm(uint8_t * __restrict dest, uint8_t * __restrict src, NSUInteger numPixels)
{
    /*
        Start with the asm statement below, and add necessary ARM/NEON instructions.
        Steps:
            Load 3 registers with weights (28, 151, 77) for averaging RGB values - MOV
            Copy those values to D registers (so they can be used in NEON instructions) - VDUP
            Loop:
                Load the next 8 pixels from src (use %1 to access argument #1, %0 for arg #0, etc) - VLD
                Do the weighted average - VMULL and VMLAL, then divide by 256 (VSHRN)
                Store the result in dest - VST1
                Decrement iteration count - SUBS
                Branch and iterate - BNE
     */
    __asm__ volatile("lsr %2, %2, #3 \n"    // divide numPixels by 2^3=8 using bitwise shift
					 // Load the weights into r4-r6
					 "mov r4, #28 \n"
					 "mov r5, #151 \n"
					 "mov r6, #77 \n"
					 // Duplicate the constants into d4-d6
					 "vdup.8 d4, r4 \n"
					 "vdup.8 d5, r5 \n"
					 "vdup.8 d6, r6 \n"
					 // Start the pixel loop
					 "1: \n"
					 // Load 8 pixels
					 "vld4.8 {d0-d3}, [r1]! \n"
					 // Perform the weighted average
					 "vmull.u8 q7, d0, d4 \n"
					 "vmlal.u8 q7, d1, d5 \n"
					 "vmlal.u8 q7, d2, d6 \n"
					 "vshrn.u16 d7, q7, #8 \n"
					 // Store the result in dest
					 "vst1.8 {d7}, [r0]! \n"
					 // Subtract from numPixels
					 "subs %2, %2, #1 \n"
					 // Branch and iterate
					 "bne 1b \n"
                     :
                     : "r"(dest), "r"(src), "r"(numPixels)
                     : "r4", "r5", "r6", "d4", "d5", "d6", "d0", "d1", "d2", "d3", "q7", "d7"
                     );
}


void convertToGrayscaleNEON_intrinsics(uint8_t * __restrict dest, uint8_t * __restrict src, NSUInteger numPixels)
{
    NSUInteger i;
    uint8x8_t rfac = vdup_n_u8 (77);
    uint8x8_t gfac = vdup_n_u8 (151);
    uint8x8_t bfac = vdup_n_u8 (28);
    NSUInteger n = numPixels / 8;
    
    // Convert per eight pixels
    for (i=0; i < n; ++i)
    {
		uint8x8x4_t rgba = vld4_u8(src);
		uint16x8_t temp = vmull_u8(rgba.val[0], rfac);
		temp = vmlal_u8(temp, rgba.val[1], gfac);
		temp = vmlal_u8(temp, rgba.val[2], bfac);
		
		uint8x8_t result = vshrn_n_u16(temp, 8);
		vst1_u8(dest, result);
		
        src  += 8*4;
        dest += 8;
    }
}

NSTimeInterval convertToGrayscale(UInt8 *pixels, NSUInteger width, NSUInteger height, CodeGenType codeGenType=CODEGEN_CPP)
{
    int n = width * height;
	
    if (codeGenType == CODEGEN_CPP)
	{
		// Convert via raw C++
        NSDate *start = [NSDate date];
		
		// Loop through the image, setting the value of the pixels
        for (int i = 0; i < n; i++)
		{
            int weight = (pixels[0] * 0.11) + (pixels[1] * 0.59) + (pixels[2] * 0.3);
            pixels[0] = weight; // Blue
            pixels[1] = weight; // Green
            pixels[2] = weight; // Red
            pixels += 4;
        }
		
        NSTimeInterval timeInterval = [start timeIntervalSinceNow];
        return timeInterval;
    }
	else
	{
        uint8_t *baseAddressGray = (uint8_t *)malloc(n);
        NSDate *start = [NSDate date];
		
        if (codeGenType == CODEGEN_NEON_INT)
            convertToGrayscaleNEON_intrinsics(baseAddressGray, pixels, n);
        else
            convertToGrayscaleNEON_asm(baseAddressGray, pixels, n);
		
        NSTimeInterval timeInterval = [start timeIntervalSinceNow];
        UInt8 *srcData = pixels;
		
        for (NSUInteger i = 0; i < (width*height); i++)
		{
            srcData[0] = baseAddressGray[i];
            srcData[1] = baseAddressGray[i];
            srcData[2] = baseAddressGray[i];
            srcData += 4;
        }
		
        free(baseAddressGray);
        return timeInterval;
    }
}

-(void)processImage
{
    CGContextRef ctx;
    CGImageRef imageRef = [[self.imageView image] CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    UInt8 *rawData = (UInt8 *)malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    NSTimeInterval timeInterval = convertToGrayscale(rawData, width, height, CODEGEN_CPP);
    NSLog(@"C++: %f ms\n", -timeInterval*1000);
    timeInterval = convertToGrayscale(rawData, width, height, CODEGEN_NEON_INT);
    NSLog(@"NEON intrinsics: %f ms\n", -timeInterval*1000);
    timeInterval = convertToGrayscale(rawData, width, height, CODEGEN_NEON_ASM);
    NSLog(@"NEON asm: %f ms\n", -timeInterval*1000);
    
    ctx = CGBitmapContextCreate(rawData,
                                CGImageGetWidth( imageRef ),
                                CGImageGetHeight( imageRef ),
                                8,
                                CGImageGetBytesPerRow( imageRef ),
                                CGImageGetColorSpace( imageRef ),
                                kCGImageAlphaPremultipliedLast );
    
    imageRef = CGBitmapContextCreateImage (ctx);
    UIImage* rawImage = [UIImage imageWithCGImage:imageRef];
    CGContextRelease(ctx);
    self.imageView.image = rawImage;
    free(rawData);
}

#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    [self.imageView setImage:image];
    [self processImage];
    
    self.imagePickerController = nil;
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
