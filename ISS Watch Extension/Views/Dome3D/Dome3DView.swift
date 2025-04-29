//
//  Dome3DView.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 2/9/25.
//  Updated by Michael on 2/25/2025
//  Copyright © 2025 Michael Stebel Consulting, LLC. All rights reserved.
//

import SwiftUI
import SceneKit

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
    
    // Theme colors as UIColors
    private let issRttRed = UIColor(cgColor: CGColor(red: 1.0, green: 0.298, blue: 0.298, alpha: 1.0))
    private let issRttDarkGray = UIColor(cgColor: CGColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0))
    
    // The three sky points, pass date & time, and satellite name. These will be passed from the parent view.
    var skyPoints: [SkyPoint]
    var date: String = ""
    var startTime: String = ""
    
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
        scene.background.contents = issRttDarkGray.withAlphaComponent(1.0)
#else
        let backgrondColor = issRttRed.withAlphaComponent(0.15)
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
        
        // Add the person figure at the center base of the dome.
        let personNode = Self.createPerson()
        personNode.name = "person"
        // Position at the center base (with feet at y = 0)
        personNode.position = SCNVector3(0, 0, 0)
        containerNode.addChildNode(personNode)
        
        // MARK: - Sky Points and Smooth Curve
        // Use the passed-in skyPoints (we're expecting exactly 3 points: A (start), B (max), C (end).
        let points = skyPoints
        let pointLabels = ["A", "B", "C"]
        for (i, point) in points.enumerated() {
            let pos = Self.convert(skyPoint: point, radius: Dome3DView.globeRadius)
            let sphere = SCNSphere(radius: 0.10)
            sphere.firstMaterial?.diffuse.contents = issRttRed
            let pointNode = SCNNode(geometry: sphere)
            pointNode.position = pos
            containerNode.addChildNode(pointNode)
            
            let labelGeometry = SCNText(string: pointLabels[i], extrusionDepth: 0.10)
            labelGeometry.font = UIFont.systemFont(ofSize: 0.7)
            labelGeometry.firstMaterial?.diffuse.contents = issRttRed
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
            
            let curvePoints = Self.sampleQuadraticBezier(p0: p0, cp: cp, p2: p2, samples: 128)
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
            let pos = SCNVector3(offset * sin(Float(phi)), 0, -offset * cos(Float(phi)))
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
        zenithLabelNode.position = SCNVector3(0, Float(Dome3DView.globeRadius + 0.1), 0)
        zenithLabelNode.scale = SCNVector3(0.5, 0.5, 0.5)
        containerNode.addChildNode(zenithLabelNode)
        
        return scene
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layer that fills the entire view.
                // We want the lower half to show a solid color.
                VStack(spacing: 0) {
                    // Top half: empty (SceneView will cover it).
                    Color.clear.frame(height: geometry.size.height * 0.5)
                    // Lower half: solid color.
#if os(watchOS)
                    Color.issrttRed.frame(height: geometry.size.height * 0.5)
                        .opacity(0.15)
#else
                    Color.userGuideBackground.frame(height: geometry.size.height * 0.5)
                        .opacity(0.15)
#endif
                }
                // Overlay the SceneView (clipped to show only the top half).
                SceneView(
                    scene: scene,
                    pointOfView: nil,
                    options: [],
                    preferredFramesPerSecond: 60
                )
                .clipShape(HorizonClipShape(fraction: 0.5))
                
#if !os(watchOS)
                // Text appearing immediately below the hemisphere.
                VStack(alignment: .leading) {
                    let paddingFactor: CGFloat = 0.020     // Used to fine-tune the text line spacing. Lower = more space, higher = less space. (Use 0.045 for simulator screenshot accuracy
                    let textPadding = geometry.size.height * -paddingFactor
                    Spacer()
                        .padding(.top, textPadding)
                    Text("SkyDome")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, textPadding * 0.8)  // Move it up to align properly under the dome
                    Text("Shows the flyover path for the pass")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, textPadding * 0.7)  // Move it up to align properly under the dome
                    Text("On: \(date),  Start (A): \(startTime).")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, textPadding * 0.5)  // Move it up to align properly under the dome
                    Text("Drag the SkyDome left or right to rotate it around you.")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.top, textPadding * 0.01)  // Move it up to align properly under the dome
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: geometry.size.height * 0.5)
#endif
                
            }
            .onAppear {
                // Recreate the scene when the view appears so that it uses the passed-in skyPoints.
                scene = makeScene()
                if let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
                    let aspect = geometry.size.width / geometry.size.height
                    let paddingFactor: CGFloat
                    
#if !os(watchOS)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        paddingFactor = 1.5
                    } else {
                        paddingFactor = 1.3
                    }
#else
                    paddingFactor = 1.2
#endif
                    
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
#if os(iOS)
        sphere.segmentCount = 512
#else
        sphere.segmentCount = 256
#endif
        let material = SCNMaterial()
        // Top hemisphere.
#if os(iOS)
        material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.65)
#else
        material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.45)
#endif
        material.isDoubleSided = true
        
#if os(iOS)
        // For iOS: force the lower half (y < 0) to be a solid color.
        material.shaderModifiers = [
            SCNShaderModifierEntryPoint.fragment: """
         if (_surface.position.y < 0.0) {
             _output.color = vec4(0.20, 0.20, 0.20, 1.00);
         }
     """
        ]
#else
        // For watchOS
        material.shaderModifiers = [
            SCNShaderModifierEntryPoint.fragment: """
         if (_surface.position.y < 0.0) {
             _output.color = vec4(0.00, 0.10, 0.00, 1.00);
         }
     """
        ]
#endif
        sphere.firstMaterial = material
        return SCNNode(geometry: sphere)
    }
    
    // We'll use createGlobe in place of createHemisphere.
    static func createHemisphere(radius: CGFloat) -> SCNNode {
        return createGlobe(radius: radius)
    }
    
    // Function to create a simple 3D figure of a person.
    static func createPerson() -> SCNNode {
        let personNode = SCNNode()
        
        // Create body: a cylinder (body height 0.5, radius 0.1)
        let body = SCNCylinder(radius: 0.1, height: 0.5)
        body.firstMaterial?.diffuse.contents = UIColor.white
        let bodyNode = SCNNode(geometry: body)
        // Position the body so its base is at y=0 (shift up by half its height)
        bodyNode.position = SCNVector3(0, 0.25, 0)
        personNode.addChildNode(bodyNode)
        
        // Create head: a sphere (radius 0.1)
        let head = SCNSphere(radius: 0.1)
        head.firstMaterial?.diffuse.contents = UIColor.white
        let headNode = SCNNode(geometry: head)
        // Position head on top of the body (body height + head radius)
        headNode.position = SCNVector3(0, 0.5 + 0.1, 0)
        personNode.addChildNode(headNode)
        
        // Create left arm: a cylinder (arm length 0.3, radius 0.05)
        let leftArm = SCNCylinder(radius: 0.05, height: 0.3)
        leftArm.firstMaterial?.diffuse.contents = UIColor.white
        let leftArmNode = SCNNode(geometry: leftArm)
        // Rotate the arm so that it lies horizontally along the x-axis.
        leftArmNode.eulerAngles.z = .pi / 2
        // Position left arm attached to the left side of the body.
        leftArmNode.position = SCNVector3(-0.15, 0.4, 0)
        personNode.addChildNode(leftArmNode)
        
        // Create right arm.
        let rightArm = SCNCylinder(radius: 0.05, height: 0.3)
        rightArm.firstMaterial?.diffuse.contents = UIColor.white
        let rightArmNode = SCNNode(geometry: rightArm)
        rightArmNode.eulerAngles.z = .pi / 2
        // Position right arm attached to the right side of the body.
        rightArmNode.position = SCNVector3(0.15, 0.4, 0)
        personNode.addChildNode(rightArmNode)
        
        return personNode
    }
    
    static func convert(skyPoint: SkyPoint, radius: CGFloat) -> SCNVector3 {
        let theta = (90 - skyPoint.elevation) * .pi / 180
        let phi = skyPoint.azimuth * .pi / 180
        let x = Float(radius * sin(CGFloat(theta)) * sin(CGFloat(phi)))
        let y = Float(radius * cos(CGFloat(theta)))
        let z = Float(-radius * sin(CGFloat(theta)) * cos(CGFloat(phi))) // Inverted z for proper orientation
        return SCNVector3(x, y, z)
    }
    
    static func convert(azimuth: Double, elevation: Double, radius: CGFloat) -> SCNVector3 {
        return convert(skyPoint: SkyPoint(azimuth: azimuth, elevation: elevation), radius: radius)
    }
    
    /// This function generates a series of points along a quadratic Bézier curve defined by three 3D points, and then “projects” those points onto a sphere with a fixed radius.
    /// Uses the Bézier formula: B(t) = (1‑t)²·p0 + 2·(1‑t)·t·cp + t²·p2
    /// - Parameters:
    ///   - p0: The starting point of the curve.
    ///   - cp: The control point. It influences the curvature, determining how the curve bends between the start and end points.
    ///   - p2: The ending point of the curve.
    ///   - samples: An integer that determines the number of intervals into which the curve is divided.
    /// - Returns: An  array of points along the curve of the sphere.
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
    
    static func createLineNodeFromPoints(_ points: [SCNVector3], color: UIColor, radius: CGFloat = 0.025) -> SCNNode {
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
            SkyPoint(azimuth: 308, elevation: 57),
            SkyPoint(azimuth: 42, elevation: 0)
        ])
        .frame(width: 200, height: 250)
        .ignoresSafeArea()
    }
}
