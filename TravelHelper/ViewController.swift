//
//  ViewController.swift
//  TravelHelper
//
//  Created by 贝贝 on 2025/4/24.
//

import UIKit
import AMapFoundationKit
import AMapLocationKit
import AMapSearchKit

class ViewController: UIViewController {
    
    private let chatView = ChatView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAMap()
        setupUI()
    }
    
    private func setupAMap() {
        // 配置高德地图
        AMapServices.shared().enableHTTPS = true
        AMapServices.shared().apiKey = "fe318d0463aac4edaa94170b858dd6a0"
        
        // 设置隐私政策
        AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapLocationManager.updatePrivacyAgree(.didAgree)
        
        // 设置搜索SDK的隐私政策
        AMapSearchAPI.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapSearchAPI.updatePrivacyAgree(.didAgree)
    }
    
    private func setupUI() {
        // 添加ChatView
        chatView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: view.topAnchor),
            chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

