
import Foundation
import UIKit

enum msgStatus: Int {
    case pos, success, timeout, over3, netError, notFind, less3, crossErr
}

enum emRegCode: Int {
    case success, less3, crossErr
}

enum userError: Error {
    case PalmAgentInitError
    case MediaPipeProcError
    case ObjectDestoryed
    case PicProcError
    case NetError
}

// isVerReg -1 0 1
// msgType=msgStatus
public struct Msg: Codable {
    let isRuning: Bool
    let isVerReg: Int
    let msgType: Int
    let handPosProp: Int
    let msg: String
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
    let r: CGFloat
}

// status=msgStatus
public struct User: Codable {
    var status: Int = 0
    var name: String = ""
    var age: Int? = 0
    var email: String? = ""
}

public struct AgentParam {
    var ctx: PalmCallback!, hold: Double = 0.6, compareHold: Double = 0.6, baseURI = ""
}

public class PalmManager {
   public  static let shared = PalmManager()
    var _ctx: PalmCallback!
    var _camview: UIImageView!
    var _palmview: PalmView!
    var _agent: PalmAgent!
    var _agentParam: AgentParam!
    // var _hold: Float = 0.6, _compareHold: Float = 0.5, _baseURI: String = ""

    public func initZTPalm(ctx: PalmCallback, hold: Float, compareHold: Float, baseURI: String) throws {
        _agentParam = AgentParam(ctx: ctx, hold: Double(hold), compareHold: Double(compareHold), baseURI: baseURI)
        _ctx = ctx
        // _hold = hold
        // _compareHold = compareHold
        // _baseURI = baseURI

        do {
            _agent = try PalmAgent(_agentParam)
            _agent.setCallBackX(ctx)
            ctx.initSuccess()
        } catch {
            throw error
            ctx.initFail()
        }
    }

    public func startCamera(Bitmap debugView: UIImageView?, CamView: UIImageView?) {
        _agent.debugView = debugView
        _camview = CamView
        _palmview = PalmView()
        _palmview.startCamera(uiView: _camview, agent: _agent)
    }

    public func setCallBackX(ctx: PalmCallback) {
        _ctx = ctx
    }

    public func startEnroll(sessionId: String, deviceId: String) throws {
        if _agent == nil {
            throw userError.ObjectDestoryed
        }

        _agent.startEnroll(sessionId, deviceId)
        // func registPalm(vCode:String);//注册成功
        // func palmState(code:Int,  msg:String)//状态信息
    }

    public func startIdentify(sessionId: String) throws {
        if _agent == nil {
            throw userError.ObjectDestoryed
        }

        _agent.startIdentify(sessionId)

        //   identifyResult( vCode:String)
    }

    public func debugImg(_ image: UIImage){
        _agent.process(image)
    }
    public func destroy() {
        _agent = nil
//        _palmview.sleepCam()
        _palmview = nil
        _camview = nil
    }

    public func sleep() {
        if _palmview != nil {
            _palmview?.sleepCam()
        }
    }

    public func awake() {
        if _palmview != nil {
            _palmview?.awakeCam()
        }
    }
}
