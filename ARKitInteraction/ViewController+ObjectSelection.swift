/*
Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import SceneKit

extension ViewController: VirtualObjectSelectionViewControllerDelegate {
    /**
     Adds the specified virtual object to the scene, placed using
     the focus square's estimate of the world-space position
     currently corresponding to the center of the screen.
     
     - Tag: PlaceVirtualObject
     */
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
            statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
            return
        }
        
        virtualObjectInteraction.selectedObject = virtualObject
        virtualObject.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
//        let minScale = min(focusSquare.lastPlane().extent.x,focusSquare.lastPlane().extent.z)
//        let objScale = minScale / (virtualObject.boundingBox.max.x-virtualObject.boundingBox.min.x)
        let objScale: Float = 0.0001
        virtualObject.scale = SCNVector3(x: objScale, y: objScale, z: objScale)

        print("x min \(virtualObject.boundingBox.min.x) y min \(virtualObject.boundingBox.min.y) z min \(virtualObject.boundingBox.min.z)")
        print("x max \(virtualObject.boundingBox.max.x) y max \(virtualObject.boundingBox.max.y) z max \(virtualObject.boundingBox.max.z)")
        
        let nodeModel = virtualObject
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
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            
        }
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObject object: VirtualObject) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject)
            }
        })

        displayObjectLoadingUI()
    }
    
    func makeBadPin(pin: SCNNode) {
        pin.constraints = []
        pin.physicsBody?.type = SCNPhysicsBodyType.dynamic
        pin.physicsBody?.categoryBitMask = 2
        pin.childNodes[0].geometry?.firstMaterial?.diffuse.contents = UIColor.red
        pin.childNodes[1].geometry?.firstMaterial?.diffuse.contents = UIColor.red
    }
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObject object: VirtualObject) {
        guard let objectIndex = virtualObjectLoader.loadedObjects.index(of: object) else {
            fatalError("Programmer error: Failed to lookup virtual object in scene.")
        }

        virtualObjectLoader.removeVirtualObject(at: objectIndex)
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in

            if node.physicsBody?.categoryBitMask == 1{
//                node.removeFromParentNode()
                makeBadPin(pin: node)
                //Kill pins
            }
        }

    }

    // MARK: Object Loading UI

    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])

        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()

        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}
