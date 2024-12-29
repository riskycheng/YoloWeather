import SwiftUI
import SceneKit

struct CharacterModelView: UIViewRepresentable {
    let modelName: String
    let isAnimating: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene(named: "Models.scnassets/\(modelName).scn")
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        
        // Set up camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 100
        sceneView.scene?.rootNode.addChildNode(ambientLight)
        
        // Add directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.position = SCNVector3(x: 1, y: 5, z: 2)
        sceneView.scene?.rootNode.addChildNode(directionalLight)
        
        // Start rotating animation if needed
        if isAnimating {
            let rotateAction = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 8.0)
            )
            sceneView.scene?.rootNode.runAction(rotateAction)
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update animation state if needed
    }
}
