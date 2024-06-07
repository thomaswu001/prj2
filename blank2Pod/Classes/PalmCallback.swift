import UIKit

public protocol PalmCallback {
    // func show()
    func palmState(code: Int, msg: String) // 状态信息

    func registPalm(vCode: String) // 注册成功

    func identifyResult(vCode: String)

    func initSuccess() // 初始化成功

    func initFail() // 初始化失败
}
