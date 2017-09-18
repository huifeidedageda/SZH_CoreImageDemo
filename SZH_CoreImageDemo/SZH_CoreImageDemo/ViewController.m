//
//  ViewController.m
//  SZH_CoreImageDemo
//
//  Created by 智衡宋 on 2017/9/16.
//  Copyright © 2017年 智衡宋. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic,strong)AVCaptureSession *captureSession;
@property (nonatomic,strong)AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic,strong)AVCaptureStillImageOutput *captureStillImageOutput;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
  
    
    [self szh_faceRecognitionFunction];
    [self szh_createConnection];
}



#pragma mark  -------------------  人脸识别功能

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
    
    NSLog(@"-----------");
    
    
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
