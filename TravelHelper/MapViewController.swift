import UIKit
import AMapFoundationKit
import AMapSearchKit
import AMapLocationKit
import MAMapKit

class MapViewController: UIViewController {
    private let mapView: MAMapView
    private let route: AMapRoute
    private let startPoint: CLLocationCoordinate2D
    private let endPoint: CLLocationCoordinate2D
    private var steps: [String] = []
    private let stepsTableView = UITableView()
    
    init(route: AMapRoute, steps: [String], startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        // 初始化地图视图
        let mapView = MAMapView(frame: .zero)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        self.mapView = mapView
        self.route = route
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.steps = steps
        
        super.init(nibName: nil, bundle: nil)
        
        // 设置代理
        mapView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMap()
    }
    
    private func setupUI() {
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 步骤视图
        stepsTableView.dataSource = self
        stepsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "StepCell")
        view.addSubview(stepsTableView)
        stepsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stepsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stepsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stepsTableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0/3.0)
        ])
        
        // 让地图不被步骤遮挡
        mapView.bringSubviewToFront(stepsTableView)
    }
    
    private func setupMap() {
        // 设置地图中心点和缩放级别
        let center = CLLocationCoordinate2D(
            latitude: (startPoint.latitude + endPoint.latitude) / 2,
            longitude: (startPoint.longitude + endPoint.longitude) / 2
        )
        mapView.setCenter(center, animated: true)
        mapView.setZoomLevel(15, animated: true)
        
        // 添加起点和终点标记
        let startAnnotation = MAPointAnnotation()
        startAnnotation.coordinate = startPoint
        startAnnotation.title = "起点"
        mapView.addAnnotation(startAnnotation)
        
        let endAnnotation = MAPointAnnotation()
        endAnnotation.coordinate = endPoint
        endAnnotation.title = "终点"
        mapView.addAnnotation(endAnnotation)
        
        // 绘制步行路线
        if let path = route.paths.first {
            print("开始绘制路线，路径数量：\(route.paths.count)")
            print("路径总距离：\(path.distance)米")
            
            var coordinates: [CLLocationCoordinate2D] = []
            
            // 使用步骤的坐标点
            if let steps = path.steps {
                print("步骤数量：\(steps.count)")
                for (index, step) in steps.enumerated() {
                    print("步骤\(index + 1): \(step.instruction ?? "")")
                    
                    // 解析步骤的折线
                    if let polyline = step.polyline {
                        let points = polyline.components(separatedBy: ";")
                        for point in points {
                            let coordinate = point.components(separatedBy: ",")
                            if coordinate.count == 2,
                               let longitude = Double(coordinate[0]),
                               let latitude = Double(coordinate[1]) {
                                coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                            }
                        }
                    }
                }
            }
            
            print("总坐标点数量：\(coordinates.count)")
            
            // 创建折线
            if !coordinates.isEmpty {
                let polyline = MAPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
                mapView.add(polyline)
                print("折线已添加到地图")
            } else {
                print("没有有效的坐标点")
            }
            
            // 调整地图视野以显示完整路线
            mapView.showAnnotations([startAnnotation, endAnnotation], animated: true)
        } else {
            print("没有找到路径")
        }
    }
}

// MARK: - MAMapViewDelegate
extension MapViewController: MAMapViewDelegate {
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation.isKind(of: MAPointAnnotation.self) {
            let pointReuseIndetifier = "pointReuseIndetifier"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as? MAPinAnnotationView
            
            if annotationView == nil {
                annotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
            
            annotationView?.canShowCallout = true
            annotationView?.animatesDrop = true
            annotationView?.isDraggable = false
            
            if annotation.title == "起点" {
                annotationView?.pinColor = MAPinAnnotationColor.green
            } else if annotation.title == "终点" {
                annotationView?.pinColor = MAPinAnnotationColor.red
            }
            
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: MAPolyline.self) {
            let renderer = MAPolylineRenderer(overlay: overlay)
            renderer?.lineWidth = 8.0
            renderer?.strokeColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.8)
            return renderer
        }
        return nil
    }
}

extension MapViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StepCell", for: indexPath)
        cell.textLabel?.text = steps[indexPath.row]
        return cell
    }
} 