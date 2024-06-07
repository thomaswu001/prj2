
import UIKit
import CryptoKit

func getIsFW()-> String{
//    return "Frameworks/ZTSDKFW.framework"
    return ""
}


func getSess(_ strVerScan:String) async -> String{
    var rtn=""
    let body:NSDictionary = [
            "deviceId": "",
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

    var _apikey = "4de6b4cc5eac4c9aa83ca930cc23b3f9"
    var _secretKey = "531bd2be40284b449cedab0f6f5bf6b5"
    var _secretKeyIMG =  "hn8uOz8o7S0zu4BGsj2LKfShw1yCkc09"
    var _baseURI = "https://develop.spidertest.net"

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



 func generateSignOfHmacSHA512(payload: String, secretKey: String) throws -> String {
    guard let keyData = secretKey.data(using: .utf8), let messageData = payload.data(using: .utf8) else {
        throw NSError(domain: "Invalid input", code: 0, userInfo: nil)
    }

    let key = SymmetricKey(data: keyData)
    let signature = HMAC<SHA512>.authenticationCode(for: messageData, using: key)

    return signature.map { String(format: "%02hhx", $0) }.joined().uppercased()
}

 func generateRandomString(length: Int) -> String {
    let letterSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    let randomString = (0 ..< length).map { _ in
        let randomIndex = Int.random(in: 0 ..< letterSet.count)
        return String(letterSet[letterSet.index(letterSet.startIndex, offsetBy: randomIndex)])
    }.joined()
    return randomString
}
