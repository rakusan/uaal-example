//
//  MyViewController.swift
//  NativeiOSApp
//
//  Created by Yoshikazu Kuramochi on 2022/10/15.
//  Copyright © 2022 unity. All rights reserved.
//

import Foundation
import UIKit
import UnityFramework

extension UIView {
    func addButton(
        title: String,
        frame: CGRect,
        color: UIColor,
        handler: @escaping () -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.frame = frame
        button.backgroundColor = color
        button.addAction(.init {_ in handler() }, for: .primaryActionTriggered)
        self.addSubview(button)
        return button
    }
}

class MyViewController : UIViewController {
    
    private let hostDelegate: AppDelegate
    private var unpauseBtn: UIButton?
    
    init(_ hostDelegate: AppDelegate) {
        self.hostDelegate = hostDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        
        // INIT UNITY
        _ = view.addButton(title: "Init", frame: CGRectMake(0, 100, 100, 44), color: .green) {
            self.hostDelegate.initUnity()
        }
        
        // SHOW UNITY
        unpauseBtn = view.addButton(title: "Show Unity", frame: CGRectMake(100, 100, 100, 44), color: .lightGray) {
            self.hostDelegate.showMainView()
        }
        
        // UNLOAD UNITY
        _ = view.addButton(title: "Unload", frame: CGRectMake(200, 100, 100, 44), color: .red) {
            self.hostDelegate.unloadButtonTouched()
        }
        
        // QUIT UNITY
        _ = view.addButton(title: "Quit", frame: CGRectMake(200, 150, 100, 44), color: .red) {
            self.hostDelegate.quitButtonTouched()
        }
    }

    func setColor(_ color: UIColor) {
        unpauseBtn?.backgroundColor = color
    }
}

@main
class AppDelegate : UIResponder, UIApplicationDelegate, UnityFrameworkListener, NativeCallsProtocol {
    
    private var appLaunchOpts: [UIApplication.LaunchOptionsKey : Any]?
    
    var window: UIWindow?
    private var viewController: MyViewController?
    private var showUnityOffButton: UIButton?
    private var ufw: UnityFramework?
    private var didQuit = false
    
    private var unityAppController: UnityAppController? {
        get { return ufw?.appController() }
    }
    
    private var unityIsInitialized: Bool {
        get { return unityAppController != nil }
    }
    
    private func loadUnityFramework() -> UnityFramework {
        let bundlePath = Bundle.main.bundlePath.appending("/Frameworks/UnityFramework.framework")
        let bundle = Bundle(path: bundlePath)!
        if !bundle.isLoaded {
            bundle.load()
        }
        
        let ufw = bundle.principalClass!.getInstance()!
        if (ufw.appController() == nil) {
            // unity is not initialized
            var header = _mh_execute_header
            ufw.setExecuteHeader(&header)
        }
        return ufw
    }

    private func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(defaultAction)
        let delegate = UIApplication.shared.delegate
        delegate?.window??.rootViewController?.present(alert, animated: true)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        appLaunchOpts = launchOptions
        
        window = UIWindow(frame: UIScreen.main.bounds)
        viewController = MyViewController(self)
        
        window?.rootViewController = viewController
        window?.backgroundColor = .red
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func initUnity() {
        if unityIsInitialized {
            showAlert(title: "Unity already initialized", msg: "Unload Unity first")
            return
        }
        if didQuit {
            showAlert(title: "Unity cannot be initialized after quit", msg: "Use unload instead")
            return
        }
        
        ufw = loadUnityFramework()
        // Set UnityFramework target for Unity-iPhone/Data folder to make Data part of a UnityFramework.framework and uncomment call to setDataBundleId
        // ODR is not supported in this case, ( if you need embedded and ODR you need to copy data )
        ufw?.setDataBundleId("com.unity3d.framework")
        ufw?.register(self)
        NSClassFromString("FrameworkLibAPI")?.registerAPIforNativeCalls(self)
        
        ufw?.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: appLaunchOpts)
        
        // set quit handler to change default behavior of exit app
        unityAppController?.quitHandler = {
            NSLog("AppController.quitHandler called")
        }
        
        let view = unityAppController!.rootView!
        
        if showUnityOffButton == nil {
            self.showUnityOffButton = view.addButton(title: "Show Main", frame: CGRectMake(0, 280, 100, 44), color: .green) {
                self.showHostMainWindow()
            }
            
            _ = view.addButton(title: "Send Msg", frame: CGRectMake(100, 280, 100, 44), color: .yellow) {
                self.sendMsgToUnity()
            }
            
            // Unload
            _ = view.addButton(title: "Unload", frame: CGRectMake(200, 280, 100, 44), color: .red) {
                self.unloadButtonTouched()
            }
            
            // Quit
            _ = view.addButton(title: "Quit", frame: CGRectMake(200, 330, 100, 44), color: .red) {
                self.quitButtonTouched()
            }
        }
    }
    
    func showMainView() {
        if !unityIsInitialized {
            showAlert(title: "Unity is not initialized", msg: "Initialize Unity first")
        } else {
            ufw?.showUnityWindow()
        }
    }
    
    func showHostMainWindow(_ colorName: String! = "") {
        if let color = UIColor(named: colorName) {
            viewController?.setColor(color)
        }
        window?.makeKeyAndVisible()
    }
    
    func sendMsgToUnity() {
        ufw?.sendMessageToGO(withName: "Cube", functionName: "ChangeColor", message: "yellow")
    }
    
    func unloadButtonTouched() {
        if !unityIsInitialized {
            showAlert(title: "Unity is not initialized", msg: "Initialize Unity first")
        } else {
            loadUnityFramework().unloadApplication()
        }
    }
    
    func quitButtonTouched() {
        if !unityIsInitialized {
            showAlert(title: "Unity is not initialized", msg: "Initialize Unity first")
        } else {
            loadUnityFramework().quitApplication(0)
        }
    }
    
    func unityDidUnload(_ notification: Notification!) {
        NSLog("unityDidUnload called")
        
        ufw?.unregisterFrameworkListener(self)
        ufw = nil
        showHostMainWindow("")
    }
    
    func unityDidQuit(_ notification: Notification!) {
        NSLog("unityDidQuit called")
        
        ufw?.unregisterFrameworkListener(self)
        ufw = nil
        didQuit = true
        showHostMainWindow("")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        unityAppController?.applicationWillResignActive(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        unityAppController?.applicationDidEnterBackground(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        unityAppController?.applicationWillEnterForeground(application)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        unityAppController?.applicationDidBecomeActive(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        unityAppController?.applicationWillTerminate(application)
    }
}
