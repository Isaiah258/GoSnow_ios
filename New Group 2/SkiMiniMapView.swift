//
//  SkiMiniMapView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/6.
//

import SwiftUI
import MapKit

// MARK: - 数据模型
struct PisteFeature {
    enum Kind { case piste(PisteDifficulty), road }
    enum PisteDifficulty: String { case green, blue, red, black }

    let name: String
    let kind: Kind
    let coordinates: [CLLocationCoordinate2D] // 折线（可多段近似曲线）
}

// MARK: - 示例数据（延庆附近随机构造）
private extension CLLocationCoordinate2D {
    static func xy(_ lat: Double, _ lon: Double) -> CLLocationCoordinate2D {
        .init(latitude: lat, longitude: lon)
    }
}

/// 二次贝塞尔采样（地理坐标直接线性插值的小范围近似，足够做“近似曲线”）
private func sampleQuadCurve(a: CLLocationCoordinate2D,
                             c: CLLocationCoordinate2D, // control
                             b: CLLocationCoordinate2D,
                             segments: Int = 24) -> [CLLocationCoordinate2D] {
    guard segments > 1 else { return [a, b] }
    var result: [CLLocationCoordinate2D] = []
    for i in 0...segments {
        let t = Double(i) / Double(segments)
        let x = (1 - t) * (1 - t) * a.longitude + 2 * (1 - t) * t * c.longitude + t * t * b.longitude
        let y = (1 - t) * (1 - t) * a.latitude  + 2 * (1 - t) * t * c.latitude  + t * t * b.latitude
        result.append(.xy(y, x))
    }
    return result
}

// 几条曲线雪道 + 一条道路
private let demoFeatures: [PisteFeature] = {
    let a1 = CLLocationCoordinate2D.xy(40.4200, 116.0000)
    let c1 = CLLocationCoordinate2D.xy(40.4220, 116.0045)
    let b1 = CLLocationCoordinate2D.xy(40.4240, 116.0090)
    let pisteGreen = PisteFeature(name: "Forest Lane", kind: .piste(.green),
                                  coordinates: sampleQuadCurve(a: a1, c: c1, b: b1, segments: 28))

    let a2 = CLLocationCoordinate2D.xy(40.4188, 115.9965)
    let c2 = CLLocationCoordinate2D.xy(40.4218, 116.0000)
    let b2 = CLLocationCoordinate2D.xy(40.4230, 116.0042)
    let pisteBlue  = PisteFeature(name: "River Bend", kind: .piste(.blue),
                                  coordinates: sampleQuadCurve(a: a2, c: c2, b: b2, segments: 22))

    let a3 = CLLocationCoordinate2D.xy(40.4192, 116.0060)
    let c3 = CLLocationCoordinate2D.xy(40.4207, 116.0020)
    let b3 = CLLocationCoordinate2D.xy(40.4236, 116.0056)
    let pisteRed   = PisteFeature(name: "North Face", kind: .piste(.red),
                                  coordinates: sampleQuadCurve(a: a3, c: c3, b: b3, segments: 18))

    let a4 = CLLocationCoordinate2D.xy(40.4176, 116.0010)
    let c4 = CLLocationCoordinate2D.xy(40.4202, 116.0072)
    let b4 = CLLocationCoordinate2D.xy(40.4219, 116.0102)
    let pisteBlack = PisteFeature(name: "Glacier Pitch", kind: .piste(.black),
                                  coordinates: sampleQuadCurve(a: a4, c: c4, b: b4, segments: 26))

    // 一条“道路”——更宽、浅灰
    let road = PisteFeature(name: "Resort Road", kind: .road, coordinates: [
        .xy(40.4185, 115.9955),
        .xy(40.4192, 115.9990),
        .xy(40.4206, 116.0025),
        .xy(40.4219, 116.0063),
        .xy(40.4231, 116.0092)
    ])

    return [pisteGreen, pisteBlue, pisteRed, pisteBlack, road]
}()

// MARK: - SwiftUI 外壳
struct SkiMapKitDemoView: View {
    @State private var useSatellite = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle(isOn: $useSatellite) {
                    Text(useSatellite ? "卫星底图" : "标准底图")
                        .font(.subheadline.weight(.semibold))
                }
                .toggleStyle(.switch)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            SkiMKMapRepresentable(features: demoFeatures, satellite: useSatellite)
                .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle("MapKit 雪道 Demo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - MapKit 封装
struct SkiMKMapRepresentable: UIViewRepresentable {
    let features: [PisteFeature]
    let satellite: Bool

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.isRotateEnabled = false
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.showsScale = false

        // 初始相机
        let center = CLLocationCoordinate2D(latitude: 40.4210, longitude: 116.0020)
        map.setRegion(.init(center: center, span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)), animated: false)

        // 添加折线
        addOverlays(on: map)

        // 初始标签
        context.coordinator.refreshLabels(on: map)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if #available(iOS 15.0, *) {
            map.preferredConfiguration = satellite
            ? MKImageryMapConfiguration()
            : MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        } else {
            map.mapType = satellite ? .satellite : .standard
        }
        context.coordinator.refreshLabels(on: map)
    }

    func makeCoordinator() -> Coordinator { Coordinator(features: features) }

    private func addOverlays(on map: MKMapView) {
        for f in features {
            let poly = MKPolyline(coordinates: f.coordinates, count: f.coordinates.count)
            switch f.kind {
            case .piste(let diff):
                poly.title = "piste|\(diff.rawValue)|\(f.name)"
            case .road:
                poly.title = "road|\(f.name)"
            }
            map.addOverlay(poly)
        }
    }

    // MARK: - Coordinator & 渲染
    final class Coordinator: NSObject, MKMapViewDelegate {
        let features: [PisteFeature]
        private var labelAnnotations: [MKAnnotation] = []

        init(features: [PisteFeature]) { self.features = features }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let r = MKPolylineRenderer(polyline: line)
            let title = line.title ?? ""

            if title.hasPrefix("road|") {
                // 道路样式
                r.strokeColor = UIColor(white: 0.25, alpha: 0.9)
                r.lineWidth = lineWidth(for: mapView.region.span, base: 3.8, far: 2.2)
                r.lineCap = .round
                r.lineJoin = .round
                return r
            }

            // 雪道样式
            // title 形如 "piste|blue|River Bend"
            let parts = title.split(separator: "|").map(String.init)
            let diff = parts.count >= 2 ? parts[1] : "blue"

            r.strokeColor = {
                switch diff {
                case "green": return UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1)
                case "blue":  return UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)
                case "red":   return UIColor(red: 0.90, green: 0.30, blue: 0.28, alpha: 1)
                case "black": return UIColor(white: 0.10, alpha: 1)
                default:      return UIColor.systemTeal
                }
            }()

            r.lineWidth = lineWidth(for: mapView.region.span, base: 4.2, far: 1.4)
            r.lineCap = .round
            r.lineJoin = .round

            // 卫星时略提升不透明度
            if mapView.mapType == .satellite { r.strokeColor = r.strokeColor?.withAlphaComponent(0.98) }
            return r
        }

        private func lineWidth(for span: MKCoordinateSpan, base: CGFloat, far: CGFloat) -> CGFloat {
            let lat = max(min(span.latitudeDelta, 0.06), 0.008) // clamp
            let t = (lat - 0.008) / (0.06 - 0.008)
            return CGFloat(base - (base - far) * t)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 调整线宽
            mapView.overlays.forEach {
                if let r = mapView.renderer(for: $0) as? MKPolylineRenderer {
                    let isRoad = ( ($0 as? MKPolyline)?.title ?? "" ).hasPrefix("road|")
                    r.lineWidth = lineWidth(for: mapView.region.span, base: isRoad ? 3.8 : 4.2, far: isRoad ? 2.2 : 1.4)
                }
            }
            // 刷新标签显隐
            refreshLabels(on: mapView)
        }

        // 计算折线“长度中点”的坐标
        private func midpointCoordinate(of coords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
            guard coords.count >= 2 else { return coords.first ?? .init() }
            // 估算每段长度（平地近似）
            func dist(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
                let dx = (a.longitude - b.longitude) * cos((a.latitude + b.latitude) * .pi / 360.0)
                let dy = (a.latitude - b.latitude)
                return sqrt(dx*dx + dy*dy)
            }
            var segLens: [Double] = []
            var total: Double = 0
            for i in 0..<(coords.count - 1) {
                let d = dist(coords[i], coords[i+1])
                segLens.append(d); total += d
            }
            let half = total / 2
            var acc: Double = 0
            for i in 0..<(coords.count - 1) {
                let d = segLens[i]
                if acc + d >= half {
                    let t = (half - acc) / d
                    let a = coords[i], b = coords[i+1]
                    let lat = a.latitude + (b.latitude - a.latitude) * t
                    let lon = a.longitude + (b.longitude - a.longitude) * t
                    return .xy(lat, lon)
                }
                acc += d
            }
            return coords[coords.count/2]
        }

        // 标签：中/近景显示；纯文字胶囊
        func refreshLabels(on map: MKMapView) {
            // 远景直接收起
            if map.region.span.latitudeDelta > 0.035 {
                map.removeAnnotations(labelAnnotations)
                labelAnnotations.removeAll()
                return
            }
            // 重建（Demo 足够；正式版可以做增量与栅格去重）
            map.removeAnnotations(labelAnnotations)
            labelAnnotations.removeAll()

            for case let line as MKPolyline in map.overlays {
                let title = line.title ?? ""
                let parts = title.split(separator: "|").map(String.init)
                // 解析名称
                let (kind, name): (String, String) = {
                    if parts.first == "road" { return ("road", parts.count >= 2 ? parts[1] : "Road") }
                    else { return ("piste", parts.count >= 3 ? parts[2] : "") }
                }()

                // 取 polyline 点
                var coords = [CLLocationCoordinate2D](repeating: .init(), count: line.pointCount)
                line.getCoordinates(&coords, range: NSRange(location: 0, length: line.pointCount))

                // 计算几何中点
                let mid = midpointCoordinate(of: coords)

                // 创建纯文字注记
                let ann = MKPointAnnotation()
                ann.coordinate = mid
                ann.title = name.isEmpty ? (kind == "road" ? "Road" : nil) : name
                if ann.title != nil {
                    labelAnnotations.append(ann)
                }
            }
            map.addAnnotations(labelAnnotations)
        }

        // 纯文字胶囊标签
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = TextLabelAnnotationView.reuseID
            var v = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? TextLabelAnnotationView
            if v == nil {
                v = TextLabelAnnotationView(annotation: annotation, reuseIdentifier: id)
            }
            v?.annotation = annotation
            return v
        }
    }
}

// MARK: - 方案A：纯文字标签视图（小胶囊）
final class TextLabelAnnotationView: MKAnnotationView {
    static let reuseID = "textLabelView"
    private let label = PaddingLabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = false
        zPriority = .max

        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        label.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.label.withAlphaComponent(0.12).cgColor
        label.layer.borderWidth = 0.5
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.sizeToFit()
        label.frame = label.bounds.insetBy(dx: -8, dy: -6) // 内边距 6×8
        bounds = label.bounds
    }

    override var annotation: MKAnnotation? {
        didSet {
            label.text = annotation?.title ?? ""
            setNeedsLayout()
        }
    }
}

final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}

// MARK: - 预览
#Preview {
    NavigationStack { SkiMapKitDemoView() }
}

