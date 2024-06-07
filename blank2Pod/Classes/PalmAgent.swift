
import CryptoKit
import Foundation
import GZIP
import MediaPipeTasksVision
import UIKit

struct Edge {
    var length: Double
    var n1: Int
    var n2: Int

    init(_ len: Double, _ n1: Int, _ n2: Int) {
        length = len
        self.n1 = n1
        self.n2 = n2
    }
}

class PalmAgent {
    var startEnroll = 0
    var startIdentify = 0
    var isRuning = 0
    var regStep = 0
    var regStepCode: [[Double]] = [[]]

    var _sessionId = "93264590539c4e469cc9a65ec56d4615"
    var _deviceId = "testIOS"
    var _apikey = "4de6b4cc5eac4c9aa83ca930cc23b3f9"
    var _secretKey = "531bd2be40284b449cedab0f6f5bf6b5"
    var _secretKeyIMG =  "hn8uOz8o7S0zu4BGsj2LKfShw1yCkc09"
    var _baseURI = ""
    var _agentParam: AgentParam!

    var _ctx: PalmCallback!
    var debugView: UIImageView!
    var torchM1: TorchModule!
    var handLandmarker: HandLandmarker!

    var localUser: [[Double]] = []
    var startTime: Date!

    var isEn = false
    var strArr = [(1013, "HandFar", "手掌偏远"), (1014, "HandClose", "手掌偏近"), (1009, "HandRight", "手掌偏右"), (1010, "HandLeft", "手掌偏左"), (1011, "HandUp", "手掌偏上"), (1012, "HandDown", "手掌偏下"), (1015, "HandFlat", "请手掌平放")]
    // 倾斜
    var handMsg = [(1009, "RightHand", "右手"), (1010, "LeftHand", "左手")]
    var msgDic: [Int: (String, String)] = [0: ("success", "返回成功"), 1005: ("reg err other resion", "其他注册失败及原因"), 2005: ("reg err exist", "注册失败：掌纹已存在"), 10053: ("the secend time not right", "2次匹配不一致"), 1002: ("", "手掌质量合格服务器处理中"), 10054: ("the third time not right", "第3次匹配不一致"), 10062: ("timeout", "查询失败:session已过期"), 10061: ("not found", "查询失败：掌纹不存在"), 2006: ("query err exist", "查询失败：掌纹不存在"), 1001: ("", "没有检测到手掌"), 10052: ("", "注册失败:session已过期"), 1006: ("query other resion", "其他查询失败及原因"), 1004: ("", "手掌质量不合格"), 10055: ("timeout", "运行超时"), -1: ("other error", "其他错误"), 1013: ("start", "开始采集"), 1007: ("lefthand", "检测到左手"), 1008: ("righthand", "检测到右手"), 10051: ("", "注册失败：掌纹已存在")]

    // let inDirectory="Frameworks/ZTSDKFW.framework"
    var inDirectory = ""
    // let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task",inDirectory: "Frameworks/ZTSDKFW.framework")
    // let filePath = Bundle.main.path(forResource: "mac20240507", ofType: "pt",inDirectory: "Frameworks/ZTSDKFW.framework")
//    init()  {
//        print("default init")
//    }
    init(_ agentParam: AgentParam) throws {
        do {
            print("init")
            _agentParam = agentParam
            inDirectory = getIsFW()
            torchM1 = module
            // checkKeyFile()
 
            _baseURI = agentParam.baseURI

            let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task", inDirectory: inDirectory)!
            let handLandmarkerOptions = HandLandmarkerOptions()
            handLandmarkerOptions.runningMode = .image
            handLandmarkerOptions.numHands = 1
            handLandmarkerOptions.minHandDetectionConfidence = 0.6
            handLandmarkerOptions.minHandPresenceConfidence = 0.6
            handLandmarkerOptions.minTrackingConfidence = 0.6
            handLandmarkerOptions.baseOptions.modelAssetPath = modelPath
            handLandmarkerOptions.baseOptions.delegate = .GPU
            handLandmarker = try HandLandmarker(options: handLandmarkerOptions)

        } catch {
//            print(error)
            throw userError.PalmAgentInitError
        }
    }

    func checkKeyFile(){
        _secretKey = "531bd2be40284b449cedab0f6f5bf6b5"
        _apikey = "4de6b4cc5eac4c9aa83ca930cc23b3f9"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("example1.txt")
        var fileNotFind=false
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            print(content)
        } catch {
            print("Error reading file")
            fileNotFind=true
        }
        if fileNotFind {
            let content = "secretKey:"+_secretKey+"\napikey:"+_apikey
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                print("File written successfully")
            } catch {
                print("Error writing to file")
            }
        }
      
      
    }
    
    private func getLM(_ img1: UIImage, _ is90: Bool) throws -> (Bool, Bool, [[CGFloat]]) {
        var goHead = false
        var lmRtn: [CGFloat]
        var rect: CGRect
        var isRight = true
        var rntxy = [[CGFloat]]()
        let start = Date()
        do {
            let mpImage = try MPImage(uiImage: img1)
            let result = try handLandmarker.detect(image: mpImage)
            if result.landmarks.count < 1 {
                throw userError.MediaPipeProcError
            }
            var landmark0 = result.landmarks[0][0]
            var (x0, y0, z0) = (CGFloat(landmark0.x), CGFloat(landmark0.y), CGFloat(landmark0.z))
            rntxy.append([x0, y0, z0])
            var landmark5 = result.landmarks[0][5]
            var (x5, y5, z5) = (CGFloat(landmark5.x), CGFloat(landmark5.y), CGFloat(landmark5.z))
            rntxy.append([x5, y5, z5])
            var landmark17 = result.landmarks[0][17]
            var (x17, y17, z17) = (CGFloat(landmark17.x), CGFloat(landmark17.y), CGFloat(landmark17.z))
            rntxy.append([x17, y17, z17])
            var landmark2 = result.landmarks[0][2]
            var (x2, y2, z2) = (CGFloat(landmark2.x), CGFloat(landmark2.y), CGFloat(landmark2.z))
            rntxy.append([x2, y2, z2])

            isRight = is90 ? y2 < y17 : x2 < x17 // 摄像头逆90镜像后 y x 反转
            // 左右参考值
            if isRight {
                rntxy.append([1.0, x17, 0.7])
            } else {
                rntxy.append([-1.0, x17, 0.2])
            }
//            print(x2,x17)
        } catch {
            throw userError.MediaPipeProcError
        }

        if !is90 { // 正确旋转
            let (errCode, en, cn) = qualityCheck(rntxy, img1.size.width)
            goHead = errCode == 0
            if goHead {
                if isRight {
                    let msg = isEn ? handMsg[0].1 : handMsg[0].2
                    _ctx.palmState(code: handMsg[0].0, msg: msg)
                } else {
                    let msg = isEn ? handMsg[1].1 : handMsg[1].2
                    _ctx.palmState(code: handMsg[1].0, msg: msg)
                }
            } else { // 错误提示
                let msg = isEn ? en : cn
                _ctx.palmState(code: errCode, msg: msg)
            }
        }

//        var nsArr:[NSNumber]=getNs2(rntxy,0)+getNs2(rntxy,1)+getNs2(rntxy,2)+getNs2(rntxy,3)

        return (goHead, isRight, rntxy)
    }

    private func getNs2(_ cfg: [[CGFloat]], _ pos: Int) -> [NSNumber] {
        let x = Float(cfg[pos][0]) as! NSNumber
        let y = Float(cfg[pos][1]) as! NSNumber
        return [x, y]
    }

    private lazy var module: TorchModule = {
//        comparepack1c  3c  20240507 foldpack comparepack20240507.pt model mac20240507
        if let filePath = Bundle.main.path(forResource: "mac20240507", ofType: "pt", inDirectory: inDirectory),
           let module = TorchModule(fileAtPath: filePath)
        {
            print("load model")
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

    func set0() {
        startEnroll = 0
        startIdentify = 0
        isRuning = 0
        regStep = 0
        startTime = Date()
        let zeroRow = Array(repeating: 0.0, count: 512)
        regStepCode = Array(repeating: zeroRow, count: 3)
    }

    func startEnroll(_ sessionId: String, _ deviceId: String) {
        _sessionId = sessionId
        _deviceId = deviceId

        set0()
        sleep(1)
        startEnroll = 1
        isRuning = 1
    }

    func startIdentify(_ sessionId: String) {
        _sessionId = sessionId
        set0()
        sleep(1)
        startIdentify = 1
        isRuning = 1
    }

    func setCallBackX(_ ctx: PalmCallback) {
        _ctx = ctx
    }

    func process(_ image: UIImage) {
        guard isRuning == 1 else {
            return
        }
        guard let (goHead, isRight, mp) = try? getLM(image, true) else {
            return
        }

        var pixelBuffer: [Float32] = []
        var b64 = ""
        do {
            var output = try? image.extractROI(mp, isRight)
            guard let (goHead, isRight2, mp2) = try? getLM(output!, false) else {
                return
            }

            output = try? output!.cropCenter(mp2, isRight2)
            output = output?.resize128()

            DispatchQueue.main.async {
                if self.debugView != nil {
                    self.debugView.image = output
                }
            }
            if Date().timeIntervalSince(startTime) > 200 {
                sendPageMsg(10055)
                set0()
                return
            }

            if !goHead {
                return
            }

            guard isRuning == 1 else {
                return
            }
            sendPageMsg(1013)
            pixelBuffer = output!.normalized()!
            b64 = img2B64(output!)
        } catch {}
        if pixelBuffer == [] {
            return
        }

        guard let code512 = torchM1.predict(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
            return
        }
        print("=============")
//        print(code512[0])
        let dblCode512: [Double] = code512.map { $0.doubleValue }

        if startIdentify == 1 {
            startIdentifyS2(dblCode512, b64)
        } else {
            startEnrollS2(dblCode512, b64)
        }
        // _ctx.identifyResult(vCode: "dfdfdfdd")
    }

    private func img2B64(_ inputImage: UIImage) -> String {
        let jpg = inputImage.jpegData(compressionQuality: 0.5)
        var z1 = NSData(data: jpg!)
//        var z2 = z1.gzipped()
        let z3 = z1.base64EncodedString()
        return z3
    }

    private func qualityCheck(_ rntxy: [[CGFloat]], _ wh: Double) -> (Int, String, String) {
//        var fr = img1.size
        var rtn = false
        let isRight = rntxy[4][0] > 0
        let x17 = rntxy[2][0]
        let x2 = rntxy[3][0]
        let z0 = rntxy[0][2]
        let z5 = rntxy[1][2]
        let z17 = rntxy[2][2]

        let cx = (rntxy[0][0] + rntxy[1][0] + rntxy[2][0]) / 3
        let cy = (rntxy[0][1] + rntxy[1][1] + rntxy[2][1]) / 3

        var pos0 = [rntxy[0][0] * wh, rntxy[0][1] * wh]
        var cxy = [cx * wh, cy * wh] // circle center
        let diffxy = [pos0[0] - cxy[0], pos0[1] - cxy[1]]
        let cr = sqrt(diffxy.map { $0 * $0 }.reduce(0, +)) // r
        let width = wh
        let height = wh
        let uprl1 = abs(0.5 - cx / width)
        let uprl2 = (0.48 - cr / width)
        let xw = (0.5 - cx / width)
//        print(cr/width,cr,wh,x2,x17,cy,z0,z5,z17)
        func runStep(_ step: Int) -> (Bool, Int) {
            var flag = false
            var code = 0
            switch step {
            case 0:
                flag = ((cr / width) < 0.1)
                code = 1013
            // 手掌偏远
            case 1:
                flag = ((cr / width) > 0.26)
                code = 1014
            // 手掌偏近
            case 2:
                code = 1009
                if isRight {
                    flag = x17 > 0.75
                } else {
                    flag = x2 > 0.75
                }
//             flag = ( abs(0.5 - cx/width) > (0.48 - cr/width)  && (0.5 - cx/width) > 0)
//             code=1009
            // 手掌偏右
            case 3:
                code = 1010
                if isRight {
                    flag = x2 < 0.25
                } else {
                    flag = x17 < 0.25
                }
//             flag = abs(0.5 - cx/width) > (0.48 - cr/width)  && (0.5 - cx/width) < 0
//             code=1010
            // 手掌偏左
            case 4:
//             flag = abs(0.5 - cx/height) > (0.48 - cr/height)  && (0.5 - cy/height) > 0
                flag = cy < 0.2
                code = 1011
            // 手掌偏上
            case 5:
                flag = cy > 0.8
//             flag = abs(0.5 - cx/height) > (0.48 - cr/height)  && (0.5 - cy/height) < 0
                code = 1012
            // 手掌偏下
            case 6:
                flag = !(isBetween(z5, -0.1, 0.1) && isBetween(z17, -0.1, 0.1))
//             flag = abs(0.5 - cx/height) > (0.48 - cr/height)  && (0.5 - cy/height) < 0
                code = 1015
            // 手掌偏下
            default:
                flag = false
            }
            flag = !flag
            return (flag, code)
        }

        var errCode = 0
        var cn = ""
        var en = ""
        for i in 0 ... 6 {
            let (tf, code) = runStep(i)
            if !tf {
                (errCode, en, cn) = strArr[i]
                break
            }
        }

        return (errCode, en, cn)
    }

    private func getRect(_ rxyxy: [CGFloat], _ fr: CGSize, _ typeid: Int) -> CGRect {
        var rtn: CGRect!
        let width = fr.height
        let height = fr.width
        switch typeid {
        case 1:
            let rxyxy2 = [rxyxy[0] * width, rxyxy[1] * height, rxyxy[2] * width, rxyxy[3] * height]
            let diffxy = [rxyxy2[0] - rxyxy2[2], rxyxy2[1] - rxyxy2[3]]
            let cr = sqrt(diffxy.map { $0 * $0 }.reduce(0, +))
            rtn = CGRect(x: rxyxy2[0] - cr, y: rxyxy2[1] - cr, width: cr * 2, height: cr * 2)

        default:
            break
        }
        return rtn
    }

    private func startIdentifyS2(_ code: [Double], _ b64: String) {
       post2Server( code,  b64,false)
    }

    func post2Server(_ code: [Double], _ b64: String,_ isReg:Bool) {
        Task {
            isRuning = 0
            sendPageMsg(1002)
            let fromServerVcode = await send2Server(isReg, code)
            if fromServerVcode==""{
                return
            }
            if isReg{
 _ctx.registPalm(vCode: fromServerVcode)
            }else{
 _ctx.identifyResult(vCode: fromServerVcode)
            }
           

            // let picSuccess = await sendImg2Server(b64, fromServerVcode)
        }
    }

    private func startEnrollS2(_ code: [Double], _ b64: String) {
        let compareHold = _agentParam.compareHold

        var similarity = 0.0
        switch regStep {
        case 0:
            regStepCode[0] = code
            regStep = 1
            _ctx.palmState(code: 1, msg: "第一次成功 请移开手掌")
            isRuning = 0
            sleep(1)
            isRuning = 1
        case 1:
            regStepCode[1] = code
            similarity = cosineSimilarity(regStepCode[0], regStepCode[1])
            if similarity > compareHold {
                regStep = 2
                _ctx.palmState(code: 1, msg: "第二次成功 请移开手掌")
                isRuning = 0
                sleep(1)
                isRuning = 1
            } else {
                sendPageMsg(10053)
//                _ctx.palmState(code: 1, msg: "2次匹配不一致")
                regStep = 0
            }
        case 2:
            regStepCode[2] = code
            let v01 = cosineSimilarity(regStepCode[0], regStepCode[1])
            let v02 = cosineSimilarity(regStepCode[0], regStepCode[2])
            let v12 = cosineSimilarity(regStepCode[2], regStepCode[1])
            let numbers = [v01, v02, v12]
            if numbers.allSatisfy({ $0 > compareHold }) {
                regStep = 3
                isRuning = 0
                let edges: [Edge] = [
                    Edge(v01, 0, 1),
                    Edge(v12, 1, 2),
                    Edge(v02, 2, 0),
                ]
                let outCode = findMinP(edges)
                post2Server( outCode,  b64,true)
            

            } else {
                sendPageMsg(10054)
//                _ctx.palmState(code: 1, msg: "第3次匹配不一致")
                regStep = 2
            }

        default:
            break
        }

//        print("Cosine similarity: \(similarity)")
    }

    private func send2Server(_ isReg: Bool, _ code512: [Double]) async -> String {
        var rtn = ""
        let dic = await fetchDataAsync(code512,isReg)
        if dic == [:] {
            return "net error"
        }
        let netRtnCode = dic["code"] as! Int
        var dicChange = [2005: 10051, 2001: 10052, 2006: 10061, 0: 0,-1:-1]
        if isReg {
            dicChange[2001] = 10062
        }
        var errCode2 = -1
        if dicChange.keys.contains(netRtnCode){
            errCode2 = dicChange[netRtnCode]!
        }
        
        if errCode2 == 0 {
            let dic2 = dic["data"] as! NSDictionary
            rtn = dic2["vcode"] as! String
        } else {
            sendPageMsg(errCode2)
        }
        return rtn
    }

    private func sendImg2Server(_ b64: String, _ vcode: String) async -> Int {
        var rtn = -1
        let contentType = "multipart/form-data"

        let body:NSDictionary = [
            "deviceId": _deviceId,
            "sessionId": _sessionId,
            "vcode": vcode,
            "palmFile": b64,
        ]
      
        do {
            let request=genReq(body,true,"/api/app/upload")
            let (data, _) = try await URLSession.shared.data(for: request)
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
               let rtn1 = jsonObject as! NSDictionary
               print("uploadImg success \(rtn1)")
            } else {
                print("数据无法解析为JSON")
            }
        } catch {
            print(error)
        }
        return rtn
    }

    func fetchDataAsync(_ code512: [Double],_ isReg:Bool) async -> NSDictionary {
        var rtn = NSDictionary()
        let resultString = code512.map { String(format: "%.5f", $0) }.joined(separator: ",")  
        let str1 = resultString.data(using: .utf8)
        let nsdata: NSData = str1 as! NSData
        let ziped = nsdata.gzipped()
        let featureData = ziped?.base64EncodedString()
        let body:NSDictionary = [
            "sessionId": _sessionId,
            "deviceId": _deviceId,
            "featureData": featureData,
        ]
        do {
            let request=genReq(body,false,"/api/app/getVcode2")
            let (data, _) = try await URLSession.shared.data(for: request)
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                rtn = jsonObject as! NSDictionary
                // print("fetchDataAsync return \(rtn)")
            } else {
                print("数据无法解析为JSON")
            }
        } catch {
            print(error)
        }
        return rtn
    }

    func getSess(_ strVerScan:String) async -> String{
        var rtn=""
        let body:NSDictionary = [
                "deviceId": _deviceId,
                "bizType": strVerScan,
            ]
            do {
            let request=genReq(body,false,"/api/dashboard/getSessionId")
                let (data, _) = try await URLSession.shared.data(for: request)
                if let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let dataDict = jsonDict["data"] as? [String: Any] {  
                    // 访问 sessionId  
                    if let sessionId = dataDict["sessionId"] as? String {  
                        rtn=sessionId // 输出: f558a52801d7498a99ef6891db35912a  
                        _sessionId=sessionId
                    }  
                } 
                } else {
                    print("数据无法解析为JSON")
                }
            } catch {
                print(error)
            }
        return rtn
    }

    func genReq(_ body:NSDictionary,_ isImg:Bool,_ subUrl:String) -> URLRequest{
        var strBody = ""
        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // print(jsonString) // 输出 JSON 字符串
                strBody = jsonString
            }
        } else {
            print("Error while creating JSON data")
        }

        let ts = Date().timeIntervalSince1970*1000
        let timestamp = String(format: "%.0f", ts)  
        let nonce = generateRandomString(length: 32)
        let payload = timestamp + "\n" + nonce + "\n" + strBody + "\n"
        let secKey=isImg ? _secretKeyIMG : _secretKey
        let sign = try! generateSignOfHmacSHA512(payload: payload, secretKey: secKey)
        let postData = strBody.data(using: .utf8)
        var request = URLRequest(url: URL(string: _baseURI+subUrl)!, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(sign, forHTTPHeaderField: "Sign")
        request.addValue(timestamp, forHTTPHeaderField: "Timestamp")
        request.addValue(nonce, forHTTPHeaderField: "Nonce")
        request.addValue(_apikey, forHTTPHeaderField: "Apikey")

        request.httpMethod = "POST"
        request.httpBody = postData
        return request
    }



    private func sendPageMsg(_ code: Int) {
        let (en, cn) = msgDic[code]!
        let rtn = isEn ? en : cn
        _ctx.palmState(code: code, msg: rtn)
    }

    private func isBetween(_ val: Double, _ v1: Double, _ v2: Double) -> Bool {
        if v1 < val && val < v2 {
            return true
        } else {
            return false
        }
    }

    private func generateRandomString(length: Int) -> String {
        let letterSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let randomString = (0 ..< length).map { _ in
            let randomIndex = Int.random(in: 0 ..< letterSet.count)
            return String(letterSet[letterSet.index(letterSet.startIndex, offsetBy: randomIndex)])
        }.joined()
        return randomString
    }

    // let random32ByteString = generateRandomString(length: 32)
    // print(random32ByteString) // 输出一个32字节长的随机字符串

    ////////////Sign//////////////////
    private func generateSignOfHmacSHA512(payload: String, secretKey: String) throws -> String {
        guard let keyData = secretKey.data(using: .utf8), let messageData = payload.data(using: .utf8) else {
            throw NSError(domain: "Invalid input", code: 0, userInfo: nil)
        }

        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA512>.authenticationCode(for: messageData, using: key)

        return signature.map { String(format: "%02hhx", $0) }.joined().uppercased()
    }

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
            return zip(a, b).map(*).reduce(0, +)
        }

        func magnitude(_ a: [Double]) -> Double {
            return sqrt(a.map { $0 * $0 }.reduce(0, +))
        }

        let dotProductValue = dotProduct(a, b)
        let magnitudeA = magnitude(a)
        let magnitudeB = magnitude(b)

        guard magnitudeA != 0 && magnitudeB != 0 else {
            return 0
        }

        return dotProductValue / (magnitudeA * magnitudeB)
    }

    private func findMinP(_ edges: [Edge]) -> [Double] {
        let code = [0, 1, 2]
        let s0 = Set(code)
        let minEdge = edges.max(by: { $0.length < $1.length })
        let arr = [minEdge!.n1, minEdge!.n2]
        let s1 = Set(arr)
        let val = s0.subtracting(s1).first!
        return regStepCode[val]
    }

    public func img2Code512(_ output:UIImage?) -> [NSNumber]{
        var pixelBuffer = output!.normalized()!
        var code512 = torchM1.predict(image: UnsafeMutableRawPointer(&pixelBuffer))
        
        return code512!
    }
    

}

// let vvvv = try? generateSignOfHmacSHA512(payload: "dfdsafdasfa", secretKey: "afdsaf")
// print(vvvv!)

// private func sendIdentify(_ code: [Double]) async {
//     sleep(1)
//     var flag=false
//         for item in localUser{
//             flag = cosineSimilarity(item, code) > 0.9
//             if flag {
//                 print (cosineSimilarity(item, code) )
//                 break
//             }
//         }
//         if flag {
//             _ctx.palmState(code: 1, msg: "用户已找到")
//         }else{
//             localUser.append(code)
//             _ctx.palmState(code: 1, msg: "用户未找到")
//         }
// }

//     private func sendReg(_ code: [Double]) async {
//         sleep(1)
//     var flag=false
//         for item in localUser{
//             flag = cosineSimilarity(item, code) > 0.9
//             if flag {
//                 print (cosineSimilarity(item, code) )
//                 break
//             }
//         }
//         if flag {
//             _ctx.palmState(code: 1, msg: "用户已存在")
//         }else{
//             localUser.append(code)
//             _ctx.palmState(code: 1, msg: "注册成功")
//         }

//     }
