//
//  ViewController.swift
//  TravelHelper
//
//  Created by 贝贝 on 2025/4/24.
//

import UIKit

class ViewController: UIViewController {
    
    private let chatView = ChatView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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

