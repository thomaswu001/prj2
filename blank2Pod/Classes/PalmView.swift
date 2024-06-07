
import AVFoundation
import UIKit

class PalmView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    var session: AVCaptureSession!
    var _imageView: UIImageView?
    var _agent: PalmAgent!
    var idx = 0
    // 创建一个后台队列
    let backgroundQueue = DispatchQueue(label: "com.yourcompany.yourvideoqueue")

    // 创建一个串行队列来处理视频帧
    let processingQueue = DispatchQueue(label: "com.yourcompany.yourprocessingqueue")

    func startCamera(uiView: UIImageView?, agent: PalmAgent) {
        _agent = agent
        _imageView = uiView
        // 初始化时可以设置默认值
        let cameraAccess = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAccess == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        print("start1")
                        self.setupCamera()
                    }
                }
            }
        } else if cameraAccess == .authorized {
            print("start2")
            setupCamera()
        } else {
            print("authorized error")
            // 摄像头访问未授权，需要提示用户去设置中开启
        }
    }

    // required init?(coder: NSCoder) {
    //     super.init(coder: coder)
    //     isOpaque = false
    // }

    func setupCamera() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("无法访问前置摄像头")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            // 设置输出，可以是视频或者图片
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

            session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .high
            guard session.canAddInput(input) else { return }
            guard session.canAddOutput(output) else { return }
            session.addInput(input)
            session.addOutput(output)
            session.commitConfiguration()

            let videoSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.videoSettings = videoSettings

            session.startRunning()
        } catch {
            print("无法访问摄像头 \(error.localizedDescription)")
        }
    }

    // AVCaptureVideoDataOutputSampleBufferDelegate方法
    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        // 将CMSampleBuffer转换为UIImage
        if let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer) {
            DispatchQueue.main.async {
                // 这里的代码会在主线程上异步执行
                // ... 更新UI或执行其他主线程任务 ...
                
                if self._imageView !== nil {
                var flipImage = UIImage(cgImage: image.cgImage!,
                                        scale: 1,
                                        orientation: UIImage.Orientation(rawValue: 3)!)

                var flipImage2 = UIImage(cgImage: flipImage.cgImage!,
                                         scale: 1,
                                         orientation: UIImage.Orientation(rawValue: 6)!)
                self._imageView!.image = flipImage2
                }
            }

            backgroundQueue.async {
                // 将视频帧传递给后台队列处理

                self.idx += 1
                // print(self.idx)
                if self.idx > 5 {
                    // PalmManager.shared.getLM1(image)
                    self.processVideoFrame(img: image)
                    self.idx = 0
                }
            }
        }
    }

    func processVideoFrame(img: UIImage) {
        _agent.process(img)
        // processingQueue.sync {  }
    }

    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let uiimg = UIImage(cgImage: cgImage)
                // 原始图片

                // 图片显示
                // imageView.image = flipImage
//                let rtn=rotateImage(uiimg,by:-90 )
                return uiimg
            }
        }
        return nil
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()

        // 停止会话
        if session.isRunning {
            session.stopRunning()
        }
    }

    func awakeCam() {
        _agent.set0()
        if !session.isRunning {
            session.startRunning()
        }
    }

    func sleepCam() {
        _agent.set0()
        if session.isRunning {
            session.stopRunning()
        }
    }
}
