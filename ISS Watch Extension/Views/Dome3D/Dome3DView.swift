//
//  Dome3DView.swift
//  DomeTest
//
//  Created by Michael Stebel on 2/9/25.
//

import SwiftUI
import SceneKit

// A simple struct to hold sky coordinates.
struct SkyPoint {
    var azimuth: Double   // in degrees, where 0° is North
    var elevation: Double // in degrees, where 0° is at the horizon and 90° is the zenith
}

/// Custom clip shape to show only the top fraction of the view.
struct HorizonClipShape: Shape {
    /// The fraction of the view's height to show (from the top).
    var fraction: CGFloat = 0.5
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clipRect = CGRect(x: rect.minX,
                              y: rect.minY,
                              width: rect.width,
                              height: rect.height * fraction)
        path.addRect(clipRect)
        return path
    }
}

struct Dome3DView: View {
    // Fixed globe radius.
    static let globeRadius: CGFloat = 2
    
    // ISSRTTRed as UIColor
    private let IssRttRed = UIColor(cgColor: CGColor(red: 1.0, green: 0.298, blue: 0.298, alpha: 1.0))
    
    // The three sky points passed from the parent.
    var skyPoints: [SkyPoint]
    
    // Rotation state so that the globe starts rotated -90° (facing west).
    @State private var rotationAngle: Double = -Double.pi/2
    @State private var lastRotation: Double = -Double.pi/2
    
    // Store the scene in a @State variable so we can update it.
    @State private var scene: SCNScene = SCNScene()
    
    // Create the SceneKit scene using the current skyPoints.
    func makeScene() -> SCNScene {
        let scene = SCNScene()
        // Make the scene's background transparent.
#if !os(watchOS)
        scene.background.contents = UIColor.blue
#else
        let backgrondColor = IssRttRed.withAlphaComponent(0.15)
        scene.background.contents = backgrondColor
#endif
        
        // Create a container node for all content so we can rotate it.
        let containerNode = SCNNode()
        containerNode.name = "container"
        scene.rootNode.addChildNode(containerNode)
        
        // MARK: - Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        
        // MARK: - Lights
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 5, 5)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // MARK: - Globe with Conditional Shading
        let globeNode = Self.createGlobe(radius: Dome3DView.globeRadius)
        containerNode.addChildNode(globeNode)
        
        // MARK: - Sky Points and Smooth Curve
        // Use the passed-in skyPoints (we're expecting exactly 3 points)
        let points = skyPoints
        let pointLabels = ["A", "B", "C"]
        for (i, point) in points.enumerated() {
            let pos = Self.convert(skyPoint: point, radius: Dome3DView.globeRadius)
            let sphere = SCNSphere(radius: 0.10)
            sphere.firstMaterial?.diffuse.contents = IssRttRed
            let pointNode = SCNNode(geometry: sphere)
            pointNode.position = pos
            containerNode.addChildNode(pointNode)
            
            let labelGeometry = SCNText(string: pointLabels[i], extrusionDepth: 0.10)
            labelGeometry.font = UIFont.systemFont(ofSize: 0.7)
            labelGeometry.firstMaterial?.diffuse.contents = IssRttRed
            let labelNode = SCNNode(geometry: labelGeometry)
            let (minBound, maxBound) = labelGeometry.boundingBox
            let dx = (maxBound.x - minBound.x) / 2
            let dy = (maxBound.y - minBound.y) / 2
            labelNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)
            // Position the label close to the sphere.
            labelNode.position = SCNVector3(pos.x, pos.y + 0.03, pos.z)
            labelNode.scale = SCNVector3(0.5, 0.5, 0.5)
            containerNode.addChildNode(labelNode)
        }
        
        if points.count == 3 {
            let p0 = Self.convert(skyPoint: points[0], radius: Dome3DView.globeRadius)
            let p1 = Self.convert(skyPoint: points[1], radius: Dome3DView.globeRadius)
            let p2 = Self.convert(skyPoint: points[2], radius: Dome3DView.globeRadius)
            
            let cp = SCNVector3(
                (4 * p1.x - p0.x - p2.x) / 2,
                (4 * p1.y - p0.y - p2.y) / 2,
                (4 * p1.z - p0.z - p2.z) / 2
            )
            
            let curvePoints = Self.sampleQuadraticBezier(p0: p0, cp: cp, p2: p2, samples: 50)
            let lineNode = Self.createLineNodeFromPoints(curvePoints, color: UIColor.white)
            containerNode.addChildNode(lineNode)
        }
        
        // MARK: - Cardinal Directions (Placed on the Ground)
        let cardinalDirections: [(label: String, azimuth: Double)] = [
            ("N", 0),
            ("E", 90),
            ("S", 180),
            ("W", 270)
        ]
        for dir in cardinalDirections {
            let phi = dir.azimuth * .pi / 180
            let offset = Float(Dome3DView.globeRadius + 0.1)
            let pos = SCNVector3(offset * sin(Float(phi)), 0, offset * cos(Float(phi)))
            let textGeometry = SCNText(string: dir.label, extrusionDepth: 0.15)
            textGeometry.font = UIFont.systemFont(ofSize: 0.8)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            let textNode = SCNNode(geometry: textGeometry)
            let (minBound, maxBound) = textGeometry.boundingBox
            let dx = (maxBound.x - minBound.x) / 2
            let dy = (maxBound.y - minBound.y) / 2
            textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)
            textNode.position = pos
            textNode.scale = SCNVector3(0.5, 0.5, 0.5)
            containerNode.addChildNode(textNode)
        }
        
        // MARK: - Zenith Marker and Label
        let zenithMarker = SCNSphere(radius: 0.06)
        zenithMarker.firstMaterial?.diffuse.contents = UIColor.white
        let zenithNode = SCNNode(geometry: zenithMarker)
        zenithNode.position = SCNVector3(0, Float(Dome3DView.globeRadius), 0)
        containerNode.addChildNode(zenithNode)
        
        let zenithLabelGeometry = SCNText(string: "Zenith", extrusionDepth: 0.10)
        zenithLabelGeometry.font = UIFont.systemFont(ofSize: 0.5)
        zenithLabelGeometry.firstMaterial?.diffuse.contents = UIColor.white
        let zenithLabelNode = SCNNode(geometry: zenithLabelGeometry)
        let (zMin, zMax) = zenithLabelGeometry.boundingBox
        let zdx = (zMax.x - zMin.x) / 2
        let zdy = (zMax.y - zMin.y) / 2
        zenithLabelNode.pivot = SCNMatrix4MakeTranslation(zdx, zdy, 0)
        zenithLabelNode.position = SCNVector3(0, Float(Dome3DView.globeRadius + 0.3), 0)
        zenithLabelNode.scale = SCNVector3(0.5, 0.5, 0.5)
        containerNode.addChildNode(zenithLabelNode)
        
        return scene
    }
    
    var body: some View {
        GeometryReader { geometry in
            SceneView(
                scene: scene,
                pointOfView: nil,
                options: [],
                preferredFramesPerSecond: 60
            )
            // Clip the view so that only the top half (above the horizon) is visible.
            .clipShape(HorizonClipShape(fraction: 0.5))
            .onAppear {
                // Recreate the scene when the view appears so that it uses the passed-in skyPoints.
                scene = makeScene()
                if let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
                    let aspect = geometry.size.width / geometry.size.height
                    let paddingFactor: CGFloat = 1.2
                    let verticalScale = Dome3DView.globeRadius * paddingFactor
                    let horizontalScale = Dome3DView.globeRadius * paddingFactor / aspect
                    let finalScale = max(verticalScale, horizontalScale)
                    cameraNode.camera?.orthographicScale = Double(finalScale)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let sensitivity: Double = 0.005
                        rotationAngle = lastRotation + Double(value.translation.width) * sensitivity
                        updateContainerRotation()
                    }
                    .onEnded { _ in
                        lastRotation = rotationAngle
                    }
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func updateContainerRotation() {
        if let containerNode = scene.rootNode.childNode(withName: "container", recursively: false) {
            containerNode.eulerAngles.y = Float(rotationAngle)
        }
    }
    
    // MARK: - Helper Functions
    
    static func createGlobe(radius: CGFloat) -> SCNNode {
        // Create a full sphere that represents the globe.
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 48
        let material = SCNMaterial()
        // Top hemisphere blue.
        material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.45)
        material.isDoubleSided = true
        // Use a shader modifier to output a solid dark green for the bottom hemisphere.
        material.shaderModifiers = [
            SCNShaderModifierEntryPoint.fragment: """
                if (_surface.position.y < 0.0) {
                    _output.color = vec4(0.0, 0.1, 0.0, 1.0);
                }
            """
        ]
        sphere.firstMaterial = material
        return SCNNode(geometry: sphere)
    }
    
    // We'll use createGlobe in place of createHemisphere.
    static func createHemisphere(radius: CGFloat) -> SCNNode {
        return createGlobe(radius: radius)
    }
    
    static func convert(skyPoint: SkyPoint, radius: CGFloat) -> SCNVector3 {
        let theta = (90 - skyPoint.elevation) * .pi / 180
        let phi = skyPoint.azimuth * .pi / 180
        let x = Float(radius * sin(CGFloat(theta)) * sin(CGFloat(phi)))
        let y = Float(radius * cos(CGFloat(theta)))
        let z = Float(radius * sin(CGFloat(theta)) * cos(CGFloat(phi)))
        return SCNVector3(x, y, z)
    }
    
    static func convert(azimuth: Double, elevation: Double, radius: CGFloat) -> SCNVector3 {
        return convert(skyPoint: SkyPoint(azimuth: azimuth, elevation: elevation), radius: radius)
    }
    
    static func sampleQuadraticBezier(p0: SCNVector3, cp: SCNVector3, p2: SCNVector3, samples: Int) -> [SCNVector3] {
        var points: [SCNVector3] = []
        let targetRadius = Float(Dome3DView.globeRadius)
        for i in 0...samples {
            let t = Float(i) / Float(samples)
            let oneMinusT = 1 - t
            let x = oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * cp.x + t * t * p2.x
            let y = oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * cp.y + t * t * p2.y
            let z = oneMinusT * oneMinusT * p0.z + 2 * oneMinusT * t * cp.z + t * t * p2.z
            var point = SCNVector3(x, y, z)
            let len = sqrt(point.x * point.x + point.y * point.y + point.z * point.z)
            if len != 0 {
                point = SCNVector3(point.x / len * targetRadius,
                                     point.y / len * targetRadius,
                                     point.z / len * targetRadius)
            }
            points.append(point)
        }
        return points
    }
    
    static func createLineNodeFromPoints(_ points: [SCNVector3], color: UIColor, radius: CGFloat = 0.035) -> SCNNode {
        let lineNode = SCNNode()
        for i in 0..<points.count - 1 {
            let segment = createCylinderLine(from: points[i], to: points[i+1], radius: radius, color: color)
            lineNode.addChildNode(segment)
        }
        return lineNode
    }
    
    static func createCylinderLine(from start: SCNVector3, to end: SCNVector3, radius: CGFloat, color: UIColor) -> SCNNode {
        let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let cylinder = SCNCylinder(radius: radius, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3((start.x + end.x) / 2,
                                   (start.y + end.y) / 2,
                                   (start.z + end.z) / 2)
        let yAxis = SCNVector3(0, 1, 0)
        let direction = normalize(vector)
        let dotProd = dotProduct(yAxis, direction)
        let angle = acos(dotProd)
        let cross = crossProduct(yAxis, direction)
        if cross.x != 0 || cross.y != 0 || cross.z != 0 {
            node.rotation = SCNVector4(cross.x, cross.y, cross.z, angle)
        }
        return node
    }
    
    static func normalize(_ vector: SCNVector3) -> SCNVector3 {
        let len = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        guard len != 0 else { return SCNVector3(0, 0, 0) }
        return SCNVector3(vector.x / len, vector.y / len, vector.z / len)
    }
    
    static func dotProduct(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        return a.x * b.x + a.y * b.y + a.z * b.z
    }
    
    static func crossProduct(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }
}

struct Dome3DView_Previews: PreviewProvider {
    static var previews: some View {
        Dome3DView(skyPoints: [
            SkyPoint(azimuth: 222, elevation: 0),
            SkyPoint(azimuth: 308, elevation: 87),
            SkyPoint(azimuth: 42, elevation: 0)
        ])
            .frame(width: 200, height: 300)
            .ignoresSafeArea()
    }
}
