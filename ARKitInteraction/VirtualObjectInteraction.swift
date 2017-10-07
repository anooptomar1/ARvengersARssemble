/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Coordinates movement and gesture interactions with virtual objects.
*/

import UIKit
import ARKit

/// - Tag: VirtualObjectInteraction
class VirtualObjectInteraction: NSObject, UIGestureRecognizerDelegate, SCNPhysicsContactDelegate {
    
    var nodeModel:SCNNode!
    let nodeName = "SketchUp"
    
    var pinNode: SCNNode = SCNNode()

    
    /// Developer setting to translate assuming the detected plane extends infinitely.
    let translateAssumingInfinitePlane = true
    
    /// The scene view to hit test against when moving virtual content.
    let sceneView: VirtualObjectARView
    
    /**
     The object that has been most recently intereacted with.
     The `selectedObject` can be moved at any time with the tap gesture.
     */
    var selectedObject: VirtualObject?
    
    /// The object that is tracked for use by the pan and rotation gestures.
    private var trackedObject: VirtualObject? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
        }
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position in `updateObjectToCurrentTrackingPosition()`.
    private var currentTrackingPosition: CGPoint?
    private var currentTranslation: CGPoint?

    init(sceneView: VirtualObjectARView) {
        self.sceneView = sceneView
        super.init()
        
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        
        // Add gestures to the `sceneView`.
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(rotationGesture)
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.scene.physicsWorld.gravity = SCNVector3(0,-1,0)
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    // MARK: - Gesture Actions
    
    @objc
    func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // Check for interaction with a new object.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                trackedObject = object
            }

        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            let translation = gesture.translation(in: sceneView)

            let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
            // The `currentTrackingPosition` is used to update the `selectedObject` in `updateObjectToCurrentTrackingPosition()`.
            currentTrackingPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
            currentTranslation = translation

            gesture.setTranslation(.zero, in: sceneView)

        case .changed:
            // Ignore changes to the pan gesture until the threshold for displacment has been exceeded.
            break

        default:
            // Clear the current position tracking.
            currentTrackingPosition = nil
            trackedObject = nil
        }
    }

    /**
     If a drag gesture is in progress, update the tracked object's position by
     converting the 2D touch location on screen (`currentTrackingPosition`) to
     3D world space.
     This method is called per frame (via `SCNSceneRendererDelegate` callbacks),
     allowing drag gestures to move virtual objects regardless of whether one
     drags a finger across the screen or moves the device through space.
     - Tag: updateObjectToCurrentTrackingPosition
     */
    @objc
    func updateObjectToCurrentTrackingPosition() {
        guard let object = trackedObject, let position = currentTrackingPosition else { return }


        
        for node in sceneView.scene.rootNode.childNodes{
            let currentPosition = CGPoint(sceneView.projectPoint(node.position))
            node.position = SCNVector3(x: Float(currentPosition.x + currentTranslation!.x), y: Float(currentPosition.y + currentTranslation!.y), z: node.position.z)
        }

        translate(object, basedOn: position, infinitePlane: translateAssumingInfinitePlane)
    }

    /// - Tag: didRotate
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
//        guard gesture.state == .changed else { return }
//
//        /*
//         - Note:
//          For looking down on the object (99% of all use cases), we need to subtract the angle.
//          To make rotation also work correctly when looking from below the object one would have to
//          flip the sign of the angle depending on whether the object is above or below the camera...
//         */
//        trackedObject?.eulerAngles.y -= Float(gesture.rotation)
//
//        gesture.rotation = 0
    }
    
    func makeCylinder(x: Float = 0, y: Float = 0, z: Float = -0.2) -> SCNNode{
        let cylinder = SCNCylinder(radius: 0.01, height: 1)
        cylinder.firstMaterial?.diffuse.contents = UIColor.red
        let cylinderNode = SCNNode()
        cylinderNode.geometry = cylinder
        cylinderNode.position = SCNVector3(x,y,z)
        return cylinderNode
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
    
    func loadPinNode() {
        let pinScene = SCNScene(named:"Models.scnassets/Polev2.dae")
        
        pinNode = pinScene!.rootNode
        
        pinNode.scale = SCNVector3(0.1, 0.1, 0.1)
    }
    
    func createNewPin(x: Float, y: Float, z: Float) -> SCNNode {
        //let newPin = pinNode.clone()
        let newPin = SCNNode()
        let cylinder = SCNCylinder(radius: 0.003, height:0.1)
        let cylinderNode = SCNNode()
        cylinderNode.geometry = cylinder
        let tag = SCNBox(width: 0.03, height:0.015, length:0.01, chamferRadius:0)
        let tagNode = SCNNode()
        tagNode.geometry = tag
        tagNode.position = SCNVector3(0,0.045,0)
        newPin.addChildNode(cylinderNode)
        newPin.addChildNode(tagNode)
        
        newPin.position = SCNVector3(x, y, z)
        
        let pinNodePhysicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.003, height: 0.1)))
        
        newPin.physicsBody = pinNodePhysicsBody
        newPin.physicsBody?.categoryBitMask = 1
        newPin.physicsBody?.collisionBitMask = 5
        newPin.physicsBody?.contactTestBitMask = 1
        
        let billboardConstraint = SCNBillboardConstraint();
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        newPin.constraints = [billboardConstraint]
        
        return newPin
    }
    
    func makeBadPin(pin: SCNNode) {
        pin.constraints = []
        pin.physicsBody?.categoryBitMask = 2
        pin.childNodes[0].geometry?.firstMaterial?.diffuse.contents = UIColor.red
        pin.childNodes[1].geometry?.firstMaterial?.diffuse.contents = UIColor.red
    }
    
    func makeStuckPin(pin: SCNNode) {
        pin.physicsBody?.type = SCNPhysicsBodyType.kinematic
        pin.childNodes[0].geometry?.firstMaterial?.diffuse.contents = UIColor.green
        pin.childNodes[1].geometry?.firstMaterial?.diffuse.contents = UIColor.green
        pin.physicsBody?.physicsShape = SCNPhysicsShape(geometry: SCNCylinder(radius: 0.03, height: 0.1))
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

    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        
        if let _ = sceneView.virtualObject(at: touchLocation) {
            // Drop a pin
            
            var hitTestOptions = [SCNHitTestOption: Any]()
            hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
            
            //If we collided with an object, add a cylinder
            //This will be a pin eventually
            let hitResults: [SCNHitTestResult]  = sceneView.hitTest(touchLocation, options: hitTestOptions)
            if let hit = hitResults.first {
                if let _ = getParent(hit.node) {
                    let cylLoc = hit.worldCoordinates
//                    sceneView.scene.rootNode.addChildNode(makeCylinder(x: cylLoc.x,y: cylLoc.y,z: cylLoc.z))
                    sceneView.scene.rootNode.addChildNode(createNewPin(x: cylLoc.x,y: cylLoc.y + 0.25,z: cylLoc.z))

                    return
                }
            }
            
//            selectedObject = tappedObject
        }
//        } else if let object = selectedObject {
//            // Teleport the object to whereever the user touched the screen.
//            translate(object, basedOn: touchLocation, infinitePlane: false)
//        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }

    /// A helper method to return the first object that is found under the provided `gesture`s touch locations.
    /// - Tag: TouchTesting
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> VirtualObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let object = sceneView.virtualObject(at: touchLocation) {
                return object
            }
        }
        
        // As a last resort look for an object under the center of the touches.
        return sceneView.virtualObject(at: gesture.center(in: view))
    }
    
    // MARK: - Update object position

    /// - Tag: DragVirtualObject
    private func translate(_ object: VirtualObject, basedOn screenPos: CGPoint, infinitePlane: Bool) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform,
            let (position, _, isOnPlane) = sceneView.worldPosition(fromScreenPosition: screenPos,
                                                                   objectPosition: object.simdPosition,
                                                                   infinitePlane: infinitePlane) else { return }
        
        /*
         Plane hit test results are generally smooth. If we did *not* hit a plane,
         smooth the movement to prevent large jumps.
         */
        object.setPosition(position, relativeTo: cameraTransform, smoothMovement: !isOnPlane)
    }
}

/// Extends `UIGestureRecognizer` to provide the center point resulting from multiple touches.
extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint {
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}
