//
//  ViewController.m
//  SZH_CoreImageDemo
//
//  Created by 智衡宋 on 2017/9/16.
//  Copyright © 2017年 智衡宋. All rights reserved.
//


#define SCR_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCR_HEIGHT [UIScreen mainScreen].bounds.size.height

#define kNum 20

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>// 陀螺仪
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{
    CGFloat x;
    CGFloat y;
    CGFloat z;
    
    int CambtnX ;
    int CambtnY ;
    
    BOOL isClick;// 判断按钮是否被点击
}
@property (nonatomic,strong)CMMotionManager *motionManager;// 陀螺仪
@property (nonatomic,strong)AVCaptureSession *captureSession;
@property (nonatomic,strong)AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic,strong)AVCaptureStillImageOutput *captureStillImageOutput;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
// 拍照按钮
@property (nonatomic,strong)UIButton *camBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
  
    
    [self szh_faceRecognitionFunction];
    [self szh_createConnection];
    
    [self.view addSubview:self.camBtn];
}



#pragma mark  -------------------  人脸识别功能

- (UIButton *)camBtn
{
    if (_camBtn == nil) {
        _camBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _camBtn.backgroundColor = [UIColor redColor ];
        
        CambtnX = [self getRandomNumber:kNum*2 to:SCR_WIDTH - (kNum*2)];
        CambtnY = [self getRandomNumber:kNum*2 to:SCR_HEIGHT - (kNum*2)];
        
        _camBtn.frame = CGRectMake(CambtnX, CambtnY, kNum*2, kNum*2);
        // 设置元角度
        _camBtn.layer.cornerRadius = 20.0;
        _camBtn.layer.borderWidth = 1.0;
        _camBtn.layer.borderColor = [UIColor clearColor].CGColor;
        _camBtn.clipsToBounds = TRUE;//去除边界
        
        [_camBtn setTitle:@"抓" forState:UIControlStateNormal];
        [_camBtn addTarget:self action:@selector(takeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _camBtn;
}

#pragma mark 拍照
- (void)takeButtonClick:(UIButton *)sender {
    // 启动陀螺仪
    [self useGyroPush];
    isClick = 1;
}

#pragma mark - 获取陀螺仪的值
- (void)useGyroPush
{
    //初始化全局管理对象
    CMMotionManager *manager = [[CMMotionManager alloc] init];
    self.motionManager = manager;
    //判断陀螺仪可不可以，判断陀螺仪是不是开启
    //    BOOL m = [manager isGyroActive];
    if ([manager isGyroAvailable]){
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        //告诉manager，更新频率是100Hz
        manager.gyroUpdateInterval = 0.01;
        //Push方式获取和处理数据
        [manager startGyroUpdatesToQueue:queue
                             withHandler:^(CMGyroData *gyroData, NSError *error)
         {
             x = gyroData.rotationRate.x;
             y = gyroData.rotationRate.y;
             z = gyroData.rotationRate.z;
             [manager stopGyroUpdates];
         }];
        
    }
}

// 获取一个随机整数，范围在[from,to），包括from，不包括to
- (int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}


- (void)szh_faceRecognitionFunction {
    
    _captureSession=[[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    //获得输入设备
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];
    //取得前置摄像头
    if (!captureDevice) {
        NSLog(@"取得前置摄像头时出现问题.");
        return;
    }
    
    NSError *error=nil; //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    [_captureSession addInput:_captureDeviceInput];
    //初始化设备输出对象，用于获得输出数据
    _captureStillImageOutput=[[AVCaptureStillImageOutput alloc]init];
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [_captureStillImageOutput setOutputSettings:outputSettings];
    
    
    //输出设置 //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) { [_captureSession addInput:_captureDeviceInput]; }
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureStillImageOutput]) { [_captureSession addOutput:_captureStillImageOutput]; } //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    _captureVideoPreviewLayer.frame = self.view.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    //将视频预览层添加到界面中
    [self.view.layer addSublayer:_captureVideoPreviewLayer];
  
    
   
 
}



//建立链接
- (void)szh_createConnection {
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc]init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *settings = @{key:value};
    [captureOutput setVideoSettings:settings];
    [self.captureSession addOutput:captureOutput];
    
    [_captureSession startRunning];
    
}


// 抽样缓存写入时所调用的委托程序
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    
    UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
    UIImage *image = [self fixOrientation:img];
    
    
    // 人脸检测
    NSArray *features = [self leftEyePositionsWithImage:image];
    
    
    NSLog(@"----------- %@", features);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (features.count >0) {
            for (int i=0;i<features.count; i++) {
                
                
                NSValue *layerRect = features[i];
                
                CGRect originalRect = [layerRect CGRectValue];
                
                CGRect getRect = [self getUIImageViewRectFromCIImageRect:originalRect];
                
                _camBtn.frame = getRect;
               
                
            }
        }
        
    });
    
    
}


#pragma mark - 判断人脸
- (NSArray *)leftEyePositionsWithImage:(UIImage *)sImage
{
    if (![self hasFace:sImage]) {
        return nil;
    }
    
    NSArray *features = [self detectFaceWithImage:sImage];
    NSMutableArray *arrM = [NSMutableArray arrayWithCapacity:features.count];
    for (CIFaceFeature *f in features) {
        [arrM addObject:[NSValue valueWithCGRect:f.bounds]];
    }
    return arrM;
}


- (BOOL)hasFace:(UIImage *)sImage
{
    NSArray *features = [self detectFaceWithImage:sImage];
    if (!features.count?YES:NO) {
    }
    return features.count?YES:NO;
}

-(NSArray *)judgeFac:(UIImage *)image
{
    NSArray *results = [self detectFaceWithImage:image];
    return results;
}
#pragma mark - faceDetectorMethods
/**识别脸部*/
-(NSArray *)detectFaceWithImage:(UIImage *)faceImag
{
    //此处是CIDetectorAccuracyHigh，若用于real-time的人脸检测，则用CIDetectorAccuracyLow，更快
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                  context:nil
                                                  options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    CIImage *ciimg = [CIImage imageWithCGImage:faceImag.CGImage];
    NSArray *features = [faceDetector featuresInImage:ciimg];
    return features;
}





/**
 *  图片GIImage转换
 *
 *  @param originAllRect
 *
 *  @return
 */
- (CGRect)getUIImageViewRectFromCIImageRect:(CGRect)originAllRect
{
    
    CGRect getRect = originAllRect;
    
    
    
    float scrSalImageW = 720/SCR_WIDTH;
    float scrSalImageH = 1280/SCR_HEIGHT;
    
    getRect.size.width = originAllRect.size.width/scrSalImageW;
    getRect.size.height = originAllRect.size.height/scrSalImageH;
    
    float hx = self.view.frame.size.width/720;
    float hy = self.view.frame.size.height/1280;
    
    getRect.origin.x = originAllRect.origin.x*hx;//*hx
    getRect.origin.y = (self.view.frame.size.height - originAllRect.origin.y*hy) - getRect.size.height;
    
    
    return getRect;
}


- (NSArray *)facedetect:(CGImageRef)image {
    
    NSDictionary *imageOptions =  [NSDictionary dictionaryWithObject:@(5) forKey:CIDetectorImageOrientation];
    CIImage *personciImage = [CIImage imageWithCGImage:image];
    NSDictionary *opts = [NSDictionary dictionaryWithObject:
                          CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector *faceDetector=[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:opts];
    NSArray *features = [faceDetector featuresInImage:personciImage options:imageOptions];
    
    if (features.count > 0) {
        
        
        NSLog(@"检测到了人脸");
        
        
    } else {
        
       NSLog(@"未检测到了人脸");
        
    }
    
    return features;
}






/**
 
 在该代理方法中，sampleBuffer是一个Core Media对象，可以引入Core Video供使用
 通过抽样缓存数据创建一个UIImage对象
 
 */

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
    UIImage *result = [[UIImage alloc] initWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
    CGImageRelease(videoImage);
    return result;
}


/**
 *  用来处理图片翻转90度
 *
 *  @param aImage
 *
 *  @return UIImage
 */
- (UIImage *)fixOrientation:(UIImage *)aImage
{
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}



/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}


#pragma mark  -------------------  实现背景虚化功能

- (void)szh_useCoreImageForDepthOfField {
    
   
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    
    //高斯模糊滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    UIImage *image = [UIImage imageNamed:@"IMG_1018.JPG"];
    //将UIImage转换为CIImage类型
    CIImage *ciImage = [[CIImage alloc]initWithImage:image];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    //设置模糊程度
    [filter setValue:@8 forKey:kCIInputRadiusKey];//默认为10
    
    //径向渐变滤镜（同心圆）
    CIFilter *radialFilter = [CIFilter filterWithName:@"CIRadialGradient"];
    //图像像素为(1080,1920);
    //将圆点设置为人物头像位置，粗略估计为中心点偏上480
    [radialFilter setValue:[CIVector vectorWithX:image.size.width / 2 Y:image.size.height / 2 + 480] forKey:@"inputCenter"];
    //内圆半径
    [radialFilter setValue:@300 forKey:@"inputRadius0"];
    //外圆半径
    [radialFilter setValue:@500 forKey:@"inputRadius1"];
    
    CIFilter *linefilter = [CIFilter filterWithName:@"CILinearGradient"];
    [linefilter setValue:[CIVector vectorWithCGPoint:CGPointMake(0, 200)] forKey:@"inputPoint0"];
    [linefilter setValue:[CIVector vectorWithCGPoint:CGPointMake(200, 200)] forKey:@"inputPoint1"];
    
    
    
    //滤镜混合
    CIFilter *maskFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    //原图
    [maskFilter setValue:ciImage forKey:kCIInputImageKey];
    //高斯模糊处理后的图片
    [maskFilter setValue:filter.outputImage forKey:kCIInputBackgroundImageKey];
    //遮盖图片，这里为径向渐变所生成
    [maskFilter setValue:radialFilter.outputImage forKey:kCIInputMaskImageKey];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef endImageRef = [context createCGImage:maskFilter.outputImage fromRect:ciImage.extent];
    imageView.image = [UIImage imageWithCGImage:endImageRef];
    
    CGImageRelease(endImageRef);


}


#pragma mark  -------------------  初次使用CoreImage


- (void)szh_testCoreImage {
    
    
    //原始图片
    UIImage *image = [UIImage imageNamed:@"test.jpg"];
    //CIImage
    CIImage *ciImage = [[CIImage alloc]initWithImage:image];
    //CIFilter(滤镜)
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    //将图片输入到滤镜中
    [blurFilter setValue:ciImage forKey:kCIInputImageKey];
    //设置模糊长度（不模糊为0，模糊最大为100）
    [blurFilter setValue:@5 forKey:kCIInputRadiusKey];
    //将处理好的图片输出
    CIImage *outCiImage = [blurFilter valueForKey:kCIOutputImageKey];
    
    //输入该滤镜中所有可以设置的参数以及相关的信息
    NSLog(@"%@",[blurFilter attributes]);
    
    //CIContext(CIImage的操作句柄)nil表示默认有CPU渲染图片（如果让GPU渲染提高效率，则应设置contextWithOptions的字典数据）
    CIContext *context = [CIContext contextWithOptions:nil];
    //获取CGImage句柄
    CGImageRef outCGImage = [context createCGImage:outCiImage fromRect:[outCiImage extent]];
    //最终获取到图片
    UIImage *blurImage = [UIImage imageWithCGImage:outCGImage];
    //释放CGImage句柄
    CGImageRelease(outCGImage);
    
    
    
    //初始化ImageView
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.image = blurImage;
    imageView.center = self.view.center;
    [self.view addSubview:imageView];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
