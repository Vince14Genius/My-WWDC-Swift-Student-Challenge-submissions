import SceneKit
import Foundation

public class Point: Object3D, HasConnectedObjects {
    public var x: CGFloat { return CGFloat(position.x) }
    public var y: CGFloat { return CGFloat(position.y) }
    public var z: CGFloat { return CGFloat(position.z) }
    
    public var connectedObjects = Set<Object3D>()
    
    let core = SCNNode(geometry: SCNSphere(radius: 0.012))
    
    public init(at position: SCNVector3, in workStation: WorkStation) {
        super.init(in: workStation)
        self.position = position
        geometry = SCNSphere(radius: 0.02)
        addChildNode(core)
        idlize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func removeSelf() {
        removeAllConnected()
        removeFromParentNode()
    }
    
    func removeAllConnected() {
        let cObjects = connectedObjects
        for object in cObjects {
            object.removeSelf()
        }
        connectedObjects = Set<Object3D>()
    }
    
    public func addConnectedObject(_ object: Line) {
        connectedObjects.insert(object)
        update()
    }
    
    public func addConnectedObject(_ object: Triangle) {
        connectedObjects.insert(object)
        update()
    }
    
    public override func move(to point: SCNVector3) {
        position = point
        
        // move all connected objects
        for object in connectedObjects {
            if let obj = object as? HasDependency {
                obj.update()
            }
        }
        update()
    }
    
    public override func startPlacing(isNewObject: Bool) {
        placingAlong(isNewObject: isNewObject)
    }
    
    override func placingAlong(isNewObject: Bool) {
        updateState(to: .placing)
        if !isNewObject || positionBeforePlacing != nil {
            positionBeforePlacing = position
        }
        // turn all connect objects to placing
        for object in connectedObjects {
            object.placingAlong(isNewObject: isNewObject)
        }
    }
    
    public override func updateState(to newState: ObjectState) {
        stateInternal = newState
        switch newState {
        case .idle:
            idlize()
        case .placing:
            idlize()
            
            let material = SCNMaterial()
            material.diffuse.contents = #colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 0.2022997359)
            material.blendMode = .add
            geometry?.materials = []
            for _ in 1...6 {
                geometry?.materials.append(material)
            }
        case .selected:
            idlize()
            let material = SCNMaterial()
            material.diffuse.contents = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.4)
            material.blendMode = .alpha
            geometry?.materials = []
            for _ in 1...6 {
                geometry?.materials.append(material)
            }
        case .hidden:
            idlize()
            isHidden = true
        }
    }
    
    override func idlize() {
        // Reset appearance to idle state
        isHidden = false
        
        let material = SCNMaterial()
        material.diffuse.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25)
        material.blendMode = .alpha
        geometry?.materials = []
        for _ in 1...6 {
            geometry?.materials.append(material)
        }
        
        let coreMaterial = SCNMaterial()
        coreMaterial.diffuse.contents = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        for _ in 1...6 {
            core.geometry?.materials.append(coreMaterial)
        }
    }
    
    public func replaceBy(_ replacePoint: Point) {
        guard replacePoint !== self else { return }
        for connected in self.connectedObjects {
            if let line = connected as? Line {
                // replace in connected line objects
                if line.pointA === self {
                    line.pointA = replacePoint
                } else {
                    line.pointB = replacePoint
                }
                replacePoint.addConnectedObject(line)
            } else if let triangle = connected as? Triangle {
                // replace in connected triangle objects
                if triangle.pointA === self {
                    triangle.pointA = replacePoint
                } else if triangle.pointB === self {
                    triangle.pointB = replacePoint
                } else {
                    triangle.pointC = replacePoint
                }
                replacePoint.addConnectedObject(triangle)
            }
        }
        connectedObjects = Set<Object3D>()
        removeSelf()
    }
}
