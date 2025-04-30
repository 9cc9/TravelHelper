import UIKit
import AMapFoundationKit
import AMapSearchKit
import MAMapKit

class ChatView: UIView {
    // 消息数组
    private var messages: [(text: String, isUser: Bool)] = []
    
    // 聊天列表
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        table.keyboardDismissMode = .interactive
        table.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        return table
    }()
    
    // 底部输入区域容器
    private let inputContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        // 添加顶部分割线
        let separator = CALayer()
        separator.backgroundColor = UIColor.systemGray5.cgColor
        view.layer.addSublayer(separator)
        view.layer.masksToBounds = true
        return view
    }()
    
    // 输入框
    private let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "请输入您的问题..."
        field.font = .systemFont(ofSize: 16)
        field.backgroundColor = .systemGray6
        field.layer.cornerRadius = 18
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.rightViewMode = .always
        return field
    }()
    
    // 发送按钮
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("发送", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return button
    }()
    
    private var bottomConstraint: NSLayoutConstraint?
    private var currentStartAddress: String?
    
    // 添加新的属性
    private var currentRoute: AMapRoute?
    private var currentStartPoint: CLLocationCoordinate2D?
    private var currentEndPoint: CLLocationCoordinate2D?
    private var currentSteps: [String]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTableView()
        setupActions()
        setupKeyboardObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // 添加子视图
        addSubview(tableView)
        addSubview(inputContainer)
        inputContainer.addSubview(textField)
        inputContainer.addSubview(sendButton)
        
        bottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 输入容器约束
            inputContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomConstraint!,
            inputContainer.heightAnchor.constraint(equalToConstant: 68),
            
            // 输入框约束
            textField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            textField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),
            textField.heightAnchor.constraint(equalToConstant: 36),
            
            // 发送按钮约束
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            
            // 聊天列表约束
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新分割线
        if let separator = inputContainer.layer.sublayers?.first {
            separator.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 0.5)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
    }
    
    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        textField.delegate = self
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(keyboardWillShow),
                                            name: UIResponder.keyboardWillShowNotification,
                                            object: nil)
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(keyboardWillHide),
                                            name: UIResponder.keyboardWillHideNotification,
                                            object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        bottomConstraint?.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        bottomConstraint?.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }
    
    @objc private func sendButtonTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        
        // 添加用户消息
        messages.append((text: text, isUser: true))
        textField.text = ""
        
        // 处理用户输入
        handleUserInput(text)
        
        reloadTableView()
    }
    
    private func handleUserInput(_ text: String) {
        if currentStartAddress == nil {
            // 第一次输入，作为起点
            currentStartAddress = text
            messages.append((text: "请输入目的地地址", isUser: false))
        } else {
            // 第二次输入，作为终点，进行步行路线规划
            let endAddress = text
            AMapService.shared.planWalkingRoute(from: currentStartAddress!, to: endAddress) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        // 显示步行路线
                        self?.messages.append((text: "步行路线规划如下：", isUser: false))
                        for step in data.steps {
                            self?.messages.append((text: step, isUser: false))
                        }
                        
                        // 显示地图按钮
                        self?.messages.append((text: "查看地图", isUser: false))
                        self?.currentStartAddress = nil
                        
                        // 保存路线数据
                        self?.currentRoute = data.route
                        self?.currentStartPoint = data.startPoint
                        self?.currentEndPoint = data.endPoint
                        self?.currentSteps = data.steps
                        
                    case .failure(let error):
                        self?.messages.append((text: "路线规划失败：\(error.localizedDescription)", isUser: false))
                        self?.currentStartAddress = nil
                    }
                    self?.reloadTableView()
                }
            }
        }
    }
    
    private func reloadTableView() {
        tableView.reloadData()
        if !messages.isEmpty {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension ChatView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.identifier, for: indexPath) as? ChatMessageCell else {
            return UITableViewCell()
        }
        
        let message = messages[indexPath.row]
        cell.configure(with: message.text, isUser: message.isUser)
        return cell
    }
    
    // 更新UITableViewDelegate方法
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        if message.text == "查看地图" {
            if let route = currentRoute,
               let steps = currentSteps,
               let startPoint = currentStartPoint,
               let endPoint = currentEndPoint {
                let mapVC = MapViewController(route: route, steps: steps, startPoint: startPoint, endPoint: endPoint)
                if let viewController = self.window?.rootViewController {
                    viewController.present(mapVC, animated: true)
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension ChatView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        return true
    }
}

func MAMapRectForCoordinateRegion(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) -> MAMapRect {
    let topLeftMapPoint = MAMapPointForCoordinate(topLeft)
    let bottomRightMapPoint = MAMapPointForCoordinate(bottomRight)
    let origin = MAMapPoint(x: min(topLeftMapPoint.x, bottomRightMapPoint.x),
                            y: min(topLeftMapPoint.y, bottomRightMapPoint.y))
    let size = MAMapSize(width: abs(topLeftMapPoint.x - bottomRightMapPoint.x),
                         height: abs(topLeftMapPoint.y - bottomRightMapPoint.y))
    return MAMapRect(origin: origin, size: size)
} 