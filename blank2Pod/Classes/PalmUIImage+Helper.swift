import Accelerate
import CoreGraphics
import Foundation
import UIKit

extension UIImage {
    func normalized() -> [Float32]? {
        guard let cgImage = cgImage else {
            return nil
        }
        let w = cgImage.width
        let h = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * w
        let bitsPerComponent = 8
        var rawBytes = [UInt8](repeating: 0, count: w * h * 4)
        rawBytes.withUnsafeMutableBytes { ptr in
            if let cgImage = self.cgImage,
               let context = CGContext(data: ptr.baseAddress,
                                       width: w,
                                       height: h,
                                       bitsPerComponent: bitsPerComponent,
                                       bytesPerRow: bytesPerRow,
                                       space: CGColorSpaceCreateDeviceRGB(),
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            {
                let rect = CGRect(x: 0, y: 0, width: w, height: h)
                context.draw(cgImage, in: rect)
            }
        }
        var normalizedBuffer = [Float32](repeating: 0, count: w * h * 3)
        // normalize the pixel buffer
        // see https://pytorch.org/hub/pytorch_vision_resnet/ for more detail
//        for i in 0 ..< w * h {
//            normalizedBuffer[i] = (Float32(rawBytes[i * 4 + 0]) / 255.0 - 0.485) / 0.229 // R
//            normalizedBuffer[w * h + i] = (Float32(rawBytes[i * 4 + 1]) / 255.0 - 0.456) / 0.224 // G
//            normalizedBuffer[w * h * 2 + i] = (Float32(rawBytes[i * 4 + 2]) / 255.0 - 0.406) / 0.225 // B
//        }
//BGR
        for i in 0 ..< w * h {
            normalizedBuffer[w * h * 2 + i] = Float32(rawBytes[i * 4 + 0]) / 127.5 - 1 // R
            normalizedBuffer[w * h + i] = Float32(rawBytes[i * 4 + 1]) / 127.5 - 1 // G
            normalizedBuffer[i] = Float32(rawBytes[i * 4 + 2]) / 127.5 - 1 // B
        }
        return normalizedBuffer
    }

    func resizeImage(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        defer {
            UIGraphicsEndImageContext()
        }
        return image
    }

    func resize128() -> UIImage {
        let newSize = CGSize(width: 128, height: 128)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        defer {
            UIGraphicsEndImageContext()
        }
        return image
    }

    func cropImage(to: CGRect) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        guard let cgImage = cgImage!.cropping(to: to) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func cropImage(topLeft: CGPoint, bottomRight: CGPoint) -> UIImage? {
        let cropRect = CGRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let cgImage = cgImage!.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage)
    }


    func rotateImage(center _: CGPoint, toDegrees degrees: CGFloat) -> UIImage {
        let image = self // 创建一个新的图形上下文，大小与原始图像相同
        let radians = degrees * .pi / 180 // 将角度转换为弧度
        let size = image.size
        let maxhw = size.height > size.width ? size.height : size.width
        let maxhw2 = maxhw / 2
        let w = size.width
        let h = size.height
        let rect = CGRect(x: 0, y: 0, width: maxhw, height: maxhw)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1)
        // 保存当前的图形上下文状态
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError("Could not get the graphics context")
        }
        // 将坐标系统旋转到指定的角度
        context.translateBy(x: maxhw2, y: maxhw2)
        context.rotate(by: radians)
        context.translateBy(x: -maxhw2, y: -maxhw2)
        // 绘制旋转后的图像
        context.draw(image.cgImage!, in: rect)
        // 从图形上下文中获取新的图像
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        defer {
            UIGraphicsEndImageContext()
        }
        return rotatedImage ?? image // 如果旋转失败，返回原始图像
    }

    func toSqr() -> UIImage {
        // 计算需要填充的正方形尺寸
        let maxSize = max(size.width, size.height)
        let squareSize = CGSize(width: maxSize, height: maxSize)

        // 创建一个新的正方形上下文
        UIGraphicsBeginImageContextWithOptions(squareSize, false, 1)
        defer {
            UIGraphicsEndImageContext()
        }
//
        // 绘制红色背景
        let redColor = UIColor.red
        redColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: squareSize))

        // 计算图片在正方形中的位置
        let xOffset = (maxSize - size.width) * 0.5
        let yOffset = (maxSize - size.height) * 0.5
        let rect = CGRect(x: xOffset, y: yOffset, width: size.width, height: size.height)

        // 绘制图片到上下文中
        draw(in: rect)

        // 从上下文中获取填充后的正方形图片
        let paddedImage = UIGraphicsGetImageFromCurrentImageContext()
        return paddedImage!
    }

    func cropCenter(_ mplm: [[CGFloat]], _ isRight: Bool) throws -> UIImage {
        let reshapeSize = CGSize(width: 128, height: 128)
        let points = [mplm[0][0], mplm[0][1], mplm[1][0], mplm[1][1], mplm[2][0], mplm[2][1], mplm[3][0], mplm[3][1]]
        let imgSize = size
        let img_w = imgSize.width
        let img_h = imgSize.height

//        let point_a = CGPoint(x: points[0] * img_w, y: points[1] * img_h)
        let point_b = CGPoint(x: points[2] * img_w, y: points[3] * img_h)
        let point_c = CGPoint(x: points[4] * img_w, y: points[5] * img_h)

//        let point_2 = CGPoint(x: (point_b.x + point_c.x) / 2, y: (point_b.y + point_c.y) / 2)
        var cropwh = abs(point_c.x - point_b.x)
        var rect: CGRect!
        if isRight {
            rect = CGRect(x: point_b.x, y: point_b.y, width: cropwh, height: cropwh)
        } else {
            rect = CGRect(x: point_c.x, y: point_c.y, width: cropwh, height: cropwh)
        }
        defer {
            UIGraphicsEndImageContext()
        }
        let cropImg = cropImage(to: rect)!
        return cropImg
    }

    func extractROI(_ mplm: [[CGFloat]], _ isRHand: Bool) throws -> UIImage {
        var finalImage: UIImage? = nil
        let reshapeSize = CGSize(width: 128, height: 128)
        let points = [mplm[0][0], mplm[0][1], mplm[1][0], mplm[1][1], mplm[2][0], mplm[2][1], mplm[3][0], mplm[3][1]]
        do {
            let imgSize = size
            let img_w = imgSize.width
            let img_h = imgSize.height

            let point_a = CGPoint(x: points[0] * img_w, y: points[1] * img_h)
            let point_b = CGPoint(x: points[2] * img_w, y: points[3] * img_h)
            let point_c = CGPoint(x: points[4] * img_w, y: points[5] * img_h)
            let point_rl = CGPoint(x: points[6] * img_w, y: points[7] * img_h)

            let adjAngle = isRHand ? 0.0 : 180.0

            let point_2 = CGPoint(x: (point_b.x + point_c.x) / 2, y: (point_b.y + point_c.y) / 2)

            var point_0 = point_b
            var point_1 = point_c
            var point_x = point_1.x - point_0.x
            var point_y = point_1.y - point_0.y

            if point_y == 0 {
                point_y = 1
            }

            let point2_x: CGFloat = point_x / point_y > 0 ? -1.0 : 1.0
            let point2_y = -abs(point_x) / point_y

            // 计算欧几里得距离
            let valley_dist = sqrt(pow(point_1.x - point_0.x, 2) + pow(point_1.y - point_0.y, 2))

            let valley_cent = point_2

            let width_prob: CGFloat = 1.0
            let height_prob: CGFloat = 1.0

            let width = valley_dist * width_prob
            let height = valley_dist * height_prob

            let move_down_prob: CGFloat = 0
            let cosa = point_1.x - point_0.x
            let move_down_dist = (valley_dist * move_down_prob) / cosa

            var rotation_angle = atan2(point_1.y - point_0.y, point_1.x - point_0.x) * 180.0 / .pi + adjAngle
            print(rotation_angle)
            let sqr1 = toSqr()
            var rot_img = sqr1.rotateImage(center: point_2, toDegrees: rotation_angle)

            let newWidth = img_w * 1.5
            let newHeight = img_h * 1.5
//            rot_img = rot_img.resizeImage(to: CGSize(width: newWidth, height: newHeight))

            let centerX = valley_cent.x
            let centerY = valley_cent.y
//
//            let ROI_img = rot_img.cropImage(to: CGRect(x: centerX - width / 2, y: centerY + move_down_dist, width: width, height: height))
//            let ROI_img = rot_img.cropImage(to: CGRect(x: 0, y: 0, width: 500, height: 500))
//            guard let cgImage = ROI_img!.cgImage else {
//                throw userError.PicProcError
//            }
            finalImage = rot_img
//            finalImage=ROI_img
        } catch {
            throw userError.PicProcError
        }
        defer {
            UIGraphicsEndImageContext()
        }
        return finalImage!
    }
}

// let resizedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
