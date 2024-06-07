//
//  ViewController.swift
//  blank2Pod
//
//  Created by x001 on 05/29/2024.
//  Copyright (c) 2024 x001. All rights reserved.
//

import UIKit
import blank2Pod

//
//  ViewController.swift
//  ZTSDKIOS
//
//  Created by narwhalSh on 2024/5/23.
//

// import ZTSDKFW
import GZIP

public class ViewController: UIViewController, PalmCallback {

    public func palmState(code _: Int, msg: String) {
        print2Label(msg)
        print("from palmState \(msg)")
    }

    public func registPalm(vCode: String) {
        sleep(1)
        print2Label(vCode + " 注册成功")
        print("from registPalm \(vCode)")
    }

    public func identifyResult(vCode: String) {
        sleep(1)
        print2Label(vCode + " 验证成功")
        print("from identifyResult \(vCode)")
    }

    public func initSuccess() {
        print2Label("initSuccess")
        print("from initSuccess")
    }

    public func initFail() {
        print2Label("initFail")
        print("from initFail")
    }

    var camView: UIImageView!
    var debugView: UIImageView!
    var label = UILabel()
    var sessReg=""
    var sessVery=""
    var url1 = "https://develop.spidertest.net"
    func print2Label(_ txt: String) {
        DispatchQueue.main.async {
            self.label.text = txt
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        Task{
            sessVery  = await getSess("SCAN")
            sessReg = await  getSess("VERIFY")
        }
//        let img = UIImage(named: "20240517111827.jpg")!
        var screenSize: CGRect = UIScreen.main.bounds
        //    print( screenSize)
        let height = screenSize.height / 2 - 100
        camView = UIImageView()
        camView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: height)
        camView.contentMode = .scaleAspectFit
        view.addSubview(camView)

        debugView = UIImageView()
        debugView.contentMode = .scaleAspectFit
        debugView.frame = CGRect(x: 0, y: height + 50, width: screenSize.width, height: height)
        view.addSubview(debugView)

        let button = newBtn(x1: 0, name: "Verify")
        button.addTarget(self, action: #selector(verifyClicked(_:)), for: .touchUpInside)
        view.addSubview(button)

        let button2 = newBtn(x1: 50, name: "Reg")
        button2.addTarget(self, action: #selector(regClicked(_:)), for: .touchUpInside)
        view.addSubview(button2)

        let button3 = newBtn(x1: 110, name: "sleepCam")
        button3.addTarget(self, action: #selector(sleepCam(_:)), for: .touchUpInside)
        view.addSubview(button3)

        let button4 = newBtn(x1: 160, name: "awakeCam")
        button4.addTarget(self, action: #selector(awakeCam(_:)), for: .touchUpInside)
        view.addSubview(button4)

        let button5 = newBtn(x1: 220, name: "destroy")
        button5.addTarget(self, action: #selector(destroy(_:)), for: .touchUpInside)
        view.addSubview(button5)

        let button6 = newBtn(x1: 270, name: "reInit")
        button6.addTarget(self, action: #selector(reInit(_:)), for: .touchUpInside)
        view.addSubview(button6)

        let button7 = newBtn(x1: 320, name: "picT1")
        button7.addTarget(self, action: #selector(picT1(_:)), for: .touchUpInside)
        view.addSubview(button7)

        label.frame = CGRect(x: 0, y: view.bounds.height - 130, width: 500, height: 50) // 放置在视图底部
        label.text = ""
        label.textColor = .red
        view.addSubview(label)

        
//        url1 = "http://192.168.1.6:5001/form"
        do {
            try PalmManager.shared.initZTPalm(ctx: self, hold: 0.5, compareHold: 0.5, baseURI: url1)
//            PalmManager.shared.startCamera(Bitmap: nil, CamView: nil)
            PalmManager.shared.startCamera(Bitmap: debugView, CamView: camView)
        } catch {
            print(error)
        }
    }

    @objc func verifyClicked(_: UIButton) {
        print("verifyClicked")
        do {
            try PalmManager.shared.startIdentify(sessionId: sessVery)
        } catch {
            print(error)
        }
    }

    @objc func regClicked(_: UIButton) {
        print("regClicked")
        do {
            try PalmManager.shared.startEnroll(sessionId: sessReg, deviceId: "")
        } catch {
            print(error)
        }
    }

    @objc func sleepCam(_: UIButton) {
        try? PalmManager.shared.sleep()
    }

    @objc func awakeCam(_: UIButton) {
        try? PalmManager.shared.awake()
    }

    @objc func destroy(_: UIButton) {
        try? PalmManager.shared.destroy()
    }

    @objc func reInit(_: UIButton) {
        do {
            try PalmManager.shared.initZTPalm(ctx: self, hold: 0.5, compareHold: 0.5, baseURI: url1)
            PalmManager.shared.startCamera(Bitmap: debugView, CamView: camView)
        } catch {
            print(error)
        }
    }

    func newBtn(x1: CGFloat, name: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(name, for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: x1, y: view.bounds.height - 60, width: 50, height: 50) // 放置在视图底部
        return button
    }

    @objc func picT1(_: UIButton) {
//        task1()
        // getBundPic()
        
    }



}
