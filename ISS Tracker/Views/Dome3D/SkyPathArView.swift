//
//  SkyPathArView.swift
//  ISS Real-Time Tracker
//
//  Created by Michael Stebel on 3/1/25.
//  Copyright © 2025 Michael Stebel Consulting, LLC. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit

struct SkyPathARView: View {
    var skyPoints: [SkyPoint]
    
    var body: some View {
        ARViewContainer(skyPoints: skyPoints)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    Text("SkyPath AR")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
            )
    }
}

struct ARViewContainer: UIViewRepresentable {
    var skyPoints: [SkyPoint]
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .automatic
        arView.session.run(config)
        
        addSkyPath(to: arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func addSkyPath(to arView: ARView) {
        let sceneAnchor = AnchorEntity(world: [0, 0, -3])
        
        let points = skyPoints.map { convert(skyPoint: $0) }
        
        if points.count == 3 {
            let p0 = points[0]
            let p1 = points[1]
            let p2 = points[2]
            let cp = SIMD3<Float>(
                (4 * p1.x - p0.x - p2.x) / 2,
                (4 * p1.y - p0.y - p2.y) / 2,
                (4 * p1.z - p0.z - p2.z) / 2
            )
            
            let curvePoints = sampleQuadraticBezier(p0: p0, cp: cp, p2: p2, samples: 128)
            let lineEntity = createLineEntity(from: curvePoints, color: UIColor(red: 1.0, green: 0.298, blue: 0.298, alpha: 1.0))
            sceneAnchor.addChild(lineEntity)
        }
        
        arView.scene.addAnchor(sceneAnchor)
    }
    
    func convert(skyPoint: SkyPoint) -> SIMD3<Float> {
        let theta = Float((90 - skyPoint.elevation) * .pi / 180)
        let phi = Float(skyPoint.azimuth * .pi / 180)
        let x = sin(theta) * sin(phi)
        let y = cos(theta)
        let z = -sin(theta) * cos(phi)
        return SIMD3<Float>(x, y, z)
    }
    
    func sampleQuadraticBezier(p0: SIMD3<Float>, cp: SIMD3<Float>, p2: SIMD3<Float>, samples: Int) -> [SIMD3<Float>] {
        var points: [SIMD3<Float>] = []
        for i in 0...samples {
            let t = Float(i) / Float(samples)
            let oneMinusT = 1 - t
            let x = oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * cp.x + t * t * p2.x
            let y = oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * cp.y + t * t * p2.y
            let z = oneMinusT * oneMinusT * p0.z + 2 * oneMinusT * t * cp.z + t * t * p2.z
            points.append(SIMD3<Float>(x, y, z))
        }
        return points
    }
    
    func createLineEntity(from points: [SIMD3<Float>], color: UIColor) -> ModelEntity {
        let lineEntity = ModelEntity()
        for i in 0..<points.count - 1 {
            let segment = createSegment(from: points[i], to: points[i + 1], color: color)
            lineEntity.addChild(segment)
        }
        return lineEntity
    }
    
    func createSegment(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor) -> ModelEntity {
        let length = simd_distance(start, end)
        let midPoint = (start + end) / 2.0
        
        let planeMesh = MeshResource.generatePlane(width: length, height: 0.02)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let segmentEntity = ModelEntity(mesh: planeMesh, materials: [material])
        
        segmentEntity.position = midPoint
        let direction = normalize(end - start)
        segmentEntity.orientation = simd_quatf(from: [1, 0, 0], to: direction)
        
        return segmentEntity
    }
}

struct SkyPathARView_Previews: PreviewProvider {
    static var previews: some View {
        SkyPathARView(skyPoints: [
            SkyPoint(azimuth: 222, elevation: 0),
            SkyPoint(azimuth: 308, elevation: 57),
            SkyPoint(azimuth: 42, elevation: 0)
        ])
    }
}
