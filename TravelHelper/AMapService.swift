import Foundation
import AMapFoundationKit
import AMapSearchKit
import AMapLocationKit
import MAMapKit

class AMapService: NSObject {
    static let shared = AMapService()
    
    private var search: AMapSearchAPI?
    private var locationManager: AMapLocationManager?
    private var completionHandler: ((Result<(steps: [String], route: AMapRoute, startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D), Error>) -> Void)?
    private var startLocation: CLLocationCoordinate2D?
    private var endLocation: CLLocationCoordinate2D?
    private var endAddress: String?
    
    private override init() {
        super.init()
        setupAMap()
    }
    
    private func setupAMap() {
        // 配置高德地图
        AMapServices.shared().enableHTTPS = true
        AMapServices.shared().apiKey = "fe318d0463aac4edaa94170b858dd6a0" // 使用正确的 API Key
        
        // 设置隐私政策
        AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapLocationManager.updatePrivacyAgree(.didAgree)
        AMapSearchAPI.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapSearchAPI.updatePrivacyAgree(.didAgree)
        
        print("高德地图配置完成，API Key: \(AMapServices.shared().apiKey)")
        
        // 初始化高德地图搜索服务
        search = AMapSearchAPI()
        search?.delegate = self
        print("搜索服务初始化完成")
        
        // 初始化定位服务
        locationManager = AMapLocationManager()
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager?.locationTimeout = 2
        locationManager?.reGeocodeTimeout = 2
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        print("定位服务初始化完成")
    }
    
    // 根据地址进行步行路线规划
    func planWalkingRoute(from startAddress: String, to endAddress: String, completion: @escaping (Result<(steps: [String], route: AMapRoute, startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D), Error>) -> Void) {
        print("开始规划步行路线")
        print("起点地址: \(startAddress)")
        print("终点地址: \(endAddress)")
        
        self.endAddress = endAddress
        completionHandler = completion
        
        // 先进行地理编码，将地址转换为坐标
        let startGeocodeRequest = AMapGeocodeSearchRequest()
        startGeocodeRequest.address = startAddress
        
        print("开始搜索起点坐标...")
        // 先搜索起点坐标
        search?.aMapGeocodeSearch(startGeocodeRequest)
    }
}

// MARK: - MAMapViewDelegate
extension AMapService: MAMapViewDelegate {
    func mapViewRequireLocationAuth(_ locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
}

// MARK: - AMapSearchDelegate
extension AMapService: AMapSearchDelegate {
    // 地理编码回调
    func onGeocodeSearchDone(_ request: AMapGeocodeSearchRequest!, response: AMapGeocodeSearchResponse!) {
        print("地理编码回调")
        print("请求地址: \(request.address)")
        print("响应结果数量: \(response.geocodes.count)")
        
        if response.geocodes.count == 0 {
            print("未找到位置")
            completionHandler?(.failure(NSError(domain: "AMapService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到位置"])))
            return
        }
        
        let location = response.geocodes.first!
        print("找到位置: 纬度 \(location.location.latitude), 经度 \(location.location.longitude)")
        
        if startLocation == nil {
            // 保存起点坐标
            startLocation = CLLocationCoordinate2D(latitude: location.location.latitude, longitude: location.location.longitude)
            print("保存起点坐标成功")
            
            // 继续搜索终点坐标
            let endGeocodeRequest = AMapGeocodeSearchRequest()
            endGeocodeRequest.address = endAddress // 使用正确的终点地址
            print("开始搜索终点坐标...")
            search?.aMapGeocodeSearch(endGeocodeRequest)
        } else {
            // 保存终点坐标
            endLocation = CLLocationCoordinate2D(latitude: location.location.latitude, longitude: location.location.longitude)
            print("保存终点坐标成功")
            
            // 进行步行路线规划
            let walkRouteRequest = AMapWalkingRouteSearchRequest()
            walkRouteRequest.origin = AMapGeoPoint.location(withLatitude: CGFloat(startLocation!.latitude), longitude: CGFloat(startLocation!.longitude))
            walkRouteRequest.destination = AMapGeoPoint.location(withLatitude: CGFloat(endLocation!.latitude), longitude: CGFloat(endLocation!.longitude))
            walkRouteRequest.showFieldsType = AMapWalkingRouteShowFieldType.all
            
            print("开始规划步行路线...")
            print("起点坐标: \(startLocation!)")
            print("终点坐标: \(endLocation!)")
            
            search?.aMapWalkingRouteSearch(walkRouteRequest)
        }
    }
    
    // 步行路线规划回调
    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
        print("路线规划回调")
        print("响应状态：\(response.count)")

        // 打印完整的高德响应

        
        if response.route == nil {
            print("未找到步行路线")
            completionHandler?(.failure(NSError(domain: "AMapService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到步行路线"])))
            return
        }
        
        let route = response.route
        var steps: [String] = []
        var coordinates: [CLLocationCoordinate2D] = []
        
        // 解析步行路线
        if let paths = route?.paths {
            print("找到 \(paths.count) 条路径")
            for path in paths {
                print("路径距离：\(path.distance)米")
                
                // 获取路径的完整折线
                if let pathPolyline = path.polyline {
                    print("路径折线数据：\(pathPolyline)")
                    let points = pathPolyline.components(separatedBy: ";")
                    for point in points {
                        let coordinate = point.components(separatedBy: ",")
                        if coordinate.count == 2 {
                            if let longitude = Double(coordinate[0]),
                               let latitude = Double(coordinate[1]),
                               !longitude.isNaN && !latitude.isNaN {
                                let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                coordinates.append(coord)
                                print("添加坐标点：\(coord)")
                            } else {
                                print("无效的坐标点：\(point)")
                            }
                        }
                    }
                } else {
                    print("路径没有折线数据")
                }
                
                if let walkSteps = path.steps {
                    print("路径包含 \(walkSteps.count) 个步骤")
                    for step in walkSteps {
                        if let instruction = step.instruction {
                            steps.append(instruction)
                            print("步骤：\(instruction)")
                        }
                    }
                }
            }
        }
        
        if let startLocation = startLocation,
           let endLocation = endLocation {
            print("路线规划成功，共 \(steps.count) 个步骤")
            print("总坐标点数量：\(coordinates.count)")
            if coordinates.isEmpty {
                print("警告：没有有效的坐标点")
            }
            completionHandler?(.success((steps: steps, route: route!, startPoint: startLocation, endPoint: endLocation)))
        } else {
            print("坐标信息不完整")
            completionHandler?(.failure(NSError(domain: "AMapService", code: -1, userInfo: [NSLocalizedDescriptionKey: "坐标信息不完整"])))
        }
    }
    
    // 错误回调
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        print("请求失败，错误信息: \(error.localizedDescription)")
        print("错误详情: \(error)")
        completionHandler?(.failure(error))
    }
}
 
