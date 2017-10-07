//
//  ViewController.swift
//  ARSceneKit
//
//  Created by Esteban Herrera on 7/7/17.
//  Copyright © 2017 Esteban Herrera. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum ObjType: Int {
    case Pin = 1
    case BadPin = 2
    case Land = 4
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var nodeModel:SCNNode!
    let nodeName = "SketchUp"
    var morphs: [SCNGeometry] = []
    
    var pinNode: SCNNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.antialiasingMode = .multisampling4X
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let modelScene = SCNScene(named:
            "art.scnassets/islands/islands.dae")!
        
        setNodeModel(modelScene: modelScene)
        
        scene.physicsWorld.gravity = SCNVector3(0,-1,0)
        scene.physicsWorld.contactDelegate = self
        
        //loadPinNode()
    }
    
    func setNodeModel(modelScene: SCNScene) {
        nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
        nodeModel.scale = SCNVector3(x: 0.000005, y: 0.000005, z: 0.000005)
        //        addTapGestureToSceneView()
        
        let geoNode1 = nodeModel.childNode(withName:"ID5003", recursively: true)
        let geoNode2 = nodeModel.childNode(withName:"ID5016", recursively: true)
        let geoNode3 = nodeModel.childNode(withName:"ID5024", recursively: true)
        let geoNode4 = nodeModel.childNode(withName:"group_0", recursively: true)
        let geoNode5 = nodeModel.childNode(withName:"group_1", recursively: true)
        
        let nodeModelPhysicsBody1 = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: SCNPhysicsShape(geometry:geoNode1!.geometry!))
        let nodeModelPhysicsBody2 = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: SCNPhysicsShape(geometry:geoNode2!.geometry!))
        let nodeModelPhysicsBody3 = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: SCNPhysicsShape(geometry:geoNode3!.geometry!))
        let nodeModelPhysicsBody4 = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: SCNPhysicsShape(geometry:geoNode4!.geometry!))
        let nodeModelPhysicsBody5 = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: SCNPhysicsShape(geometry:geoNode5!.geometry!))
        
        geoNode1?.physicsBody = nodeModelPhysicsBody1
        geoNode2?.physicsBody = nodeModelPhysicsBody2
        geoNode3?.physicsBody = nodeModelPhysicsBody3
        geoNode4?.physicsBody = nodeModelPhysicsBody4
        geoNode5?.physicsBody = nodeModelPhysicsBody5
        
        geoNode1?.physicsBody?.contactTestBitMask = 1
        geoNode1?.physicsBody?.collisionBitMask = 1
        geoNode1?.physicsBody?.categoryBitMask = 4
        geoNode2?.physicsBody?.contactTestBitMask = 1
        geoNode2?.physicsBody?.collisionBitMask = 1
        geoNode2?.physicsBody?.categoryBitMask = 4
        geoNode3?.physicsBody?.contactTestBitMask = 1
        geoNode3?.physicsBody?.collisionBitMask = 1
        geoNode3?.physicsBody?.categoryBitMask = 4
        geoNode4?.physicsBody?.contactTestBitMask = 1
        geoNode4?.physicsBody?.collisionBitMask = 1
        geoNode4?.physicsBody?.categoryBitMask = 4
        geoNode5?.physicsBody?.contactTestBitMask = 1
        geoNode5?.physicsBody?.collisionBitMask = 1
        geoNode5?.physicsBody?.categoryBitMask = 4
    }
    
    func loadPinNode() {
        let pinScene = SCNScene(named:"art.scnassets/Polev2.dae")
        
        pinNode = pinScene!.rootNode
        
        pinNode.scale = SCNVector3(0.1, 0.1, 0.1)
    }
    
    func createNewPin(x: Float, y: Float, z: Float) -> SCNNode {
        //let newPin = pinNode.clone()
        let newPin = SCNNode()
        let cylinder = SCNCylinder(radius: 0.003, height:0.038)
        let cylinderNode = SCNNode()
        cylinderNode.geometry = cylinder
        let tag = SCNBox(width: 0.03, height:0.015, length:0.01, chamferRadius:0)
        let tagNode = SCNNode()
        tagNode.geometry = tag
        tagNode.position = SCNVector3(0,0.015,0)
        newPin.addChildNode(cylinderNode)
        newPin.addChildNode(tagNode)
        
        newPin.position = SCNVector3(x, y, z)
        
        let pinNodePhysicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.003, height: 0.038)))
        
        newPin.physicsBody = pinNodePhysicsBody
        newPin.physicsBody?.categoryBitMask = 1
        newPin.physicsBody?.collisionBitMask = 5
        
        return newPin
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    func makeCylinder(x: Float = 0, y: Float = 0, z: Float = -0.2) -> SCNNode{
        let cylinder = SCNCylinder(radius: 0.01, height: 1)
        cylinder.firstMaterial?.diffuse.contents = UIColor.red
        let cylinderNode = SCNNode()
        cylinderNode.geometry = cylinder
        cylinderNode.position = SCNVector3(x,y,z)
        return cylinderNode
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let location = touches.first!.location(in: sceneView)
        // Let's test if a 3D Object was touch
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true

        //If we collided with an object, add a cylinder
        //This will be a pin eventually
        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        if let hit = hitResults.first {
            if let _ = getParent(hit.node) {
                let cylLoc = hit.worldCoordinates
                sceneView.scene.rootNode.addChildNode(createNewPin(x: cylLoc.x,y: cylLoc.y + 0.25,z: cylLoc.z))
                print("A wild cylinder appeared at x=\(cylLoc.x) y=\(cylLoc.y) z=\(cylLoc.z)")
                return
            }
        }

        // No object was touch? Try feature points
        let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)

        if let hit = hitResultsFeaturePoints.first {

            // Get the rotation matrix of the camera
            let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 0, 0))

            // Combine the matrices
            let finalTransform = simd_mul(hit.worldTransform, rotate)
            sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
            //sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
        }

    }
    
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                let modelClone = self.nodeModel.clone()
                modelClone.position = SCNVector3Zero
                
                // Add model as a child of the node
                node.addChildNode(modelClone)
            }
        }
    }
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func makeBadPin(pin: SCNNode) {
        pin.physicsBody?.categoryBitMask = 2
        pin.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
    }
    
    func makeStuckPin(pin: SCNNode) {
        pin.physicsBody?.type = SCNPhysicsBodyType.kinematic
        pin.geometry?.firstMaterial?.diffuse.contents = UIColor.green
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if (contact.nodeA.physicsBody?.categoryBitMask == 1 && contact.nodeB.physicsBody?.categoryBitMask == 1) {
            if (contact.nodeA.physicsBody?.type == SCNPhysicsBodyType.dynamic) {
                makeBadPin(pin: contact.nodeA)
            }
            if (contact.nodeB.physicsBody?.type == SCNPhysicsBodyType.dynamic) {
                makeBadPin(pin: contact.nodeB)
            }
        }
        else if (contact.nodeA.physicsBody?.categoryBitMask == 1) {
            makeStuckPin(pin: contact.nodeA)
        }
        else if (contact.nodeB.physicsBody?.categoryBitMask == 1) {
            makeStuckPin(pin: contact.nodeB)
        }
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
