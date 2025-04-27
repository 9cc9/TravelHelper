import UIKit
import AMapFoundationKit
import AMapSearchKit
import AMapLocationKit
import MAMapKit

class MapViewController: UIViewController {
    private var mapView: MAMapView!
    private var route: AMapRoute?
    private var startPoint: CLLocationCoordinate2D?
    private var endPoint: CLLocationCoordinate2D?
    
    init(route: AMapRoute, startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        self.route = route
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        showRoute()
    }
    
    private func setupMapView() {
        mapView = MAMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        view.addSubview(mapView)
        
        // 设置地图样式
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.zoomLevel = 15
    }
    
    private func showRoute() {
        guard let route = route,
              let startPoint = startPoint,
              let endPoint = endPoint else { return }
        
        // 添加起点和终点标注
        let startAnnotation = MAPointAnnotation()
        startAnnotation.coordinate = startPoint
        startAnnotation.title = "起点"
        mapView.addAnnotation(startAnnotation)
        
        let endAnnotation = MAPointAnnotation()
        endAnnotation.coordinate = endPoint
        endAnnotation.title = "终点"
        mapView.addAnnotation(endAnnotation)
        
        // 显示路线
        if let path = route.paths.first {
            // 解析路线坐标字符串
            var coordinates = parsePolylineString(path.polyline)
            
            // 创建折线
            let polyline = MAPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
            mapView.add(polyline)
            
            // 调整地图视野以显示整条路线
            mapView.showAnnotations([startAnnotation, endAnnotation], animated: true)
        }
    }
    
    // 解析高德地图的路线坐标字符串
    private func parsePolylineString(_ polylineString: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let points = polylineString.components(separatedBy: ";")
        
        for point in points {
            let components = point.components(separatedBy: ",")
            if components.count == 2,
               let longitude = Double(components[0]),
               let latitude = Double(components[1]) {
                coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        
        return coordinates
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
            
            annotationView!.canShowCallout = true
            annotationView!.animatesDrop = true
            annotationView!.isDraggable = false
            
            if annotation.title == "起点" {
                annotationView!.pinColor = .green
            } else if annotation.title == "终点" {
                annotationView!.pinColor = .red
            }
            
            return annotationView!
        }
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: MAPolyline.self) {
            let renderer = MAPolylineRenderer(overlay: overlay)
            renderer?.lineWidth = 8.0
            renderer?.strokeColor = UIColor.blue
            return renderer
        }
        return nil
    }
} 