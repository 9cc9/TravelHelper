import UIKit

class ChatMessageCell: UITableViewCell {
    static let identifier = "ChatMessageCell"
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        
        // 创建但不激活约束
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: String, isUser: Bool) {
        messageLabel.text = message
        
        // 停用之前的约束
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        
        if isUser {
            // 用户消息样式
            bubbleView.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            messageLabel.textColor = .white
            trailingConstraint?.isActive = true
            
            // 设置用户消息的特殊圆角
            let path = UIBezierPath(roundedRect: bubbleView.bounds,
                                  byRoundingCorners: [.topLeft, .topRight, .bottomLeft],
                                  cornerRadii: CGSize(width: 16, height: 16))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            bubbleView.layer.mask = mask
        } else {
            // AI消息样式
            bubbleView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            messageLabel.textColor = .black
            leadingConstraint?.isActive = true
            
            // 设置AI消息的特殊圆角
            let path = UIBezierPath(roundedRect: bubbleView.bounds,
                                  byRoundingCorners: [.topLeft, .topRight, .bottomRight],
                                  cornerRadii: CGSize(width: 16, height: 16))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            bubbleView.layer.mask = mask
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新气泡形状
        if let text = messageLabel.text, !text.isEmpty {
            let isUser = bubbleView.backgroundColor == UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            let corners: UIRectCorner = isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
            let path = UIBezierPath(roundedRect: bubbleView.bounds,
                                  byRoundingCorners: corners,
                                  cornerRadii: CGSize(width: 16, height: 16))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            bubbleView.layer.mask = mask
        }
    }
} 