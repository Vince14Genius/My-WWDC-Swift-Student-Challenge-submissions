import SceneKit
import Foundation

public class Line: Object3D, HasConnectedObjects, HasDependency {
    public var pointA: Point { // self.position should be equal to pointA.position
        didSet {
            update()
        }
    }
    public var pointB: Point {
        didSet {
            update()
        }
    }
    
    public var connectedObjects = Set<Object3D>()
    let core = SCNNode()
    let coreCore = SCNNode()
    
    public init(from pointA: Point, to pointB: Point, in workStation: WorkStation) {
        self.pointA = pointA
        self.pointB = pointB
        super.init(in: workStation)
        
        pointA.addConnectedObject(self)
        pointB.addConnectedObject(self)
        
        addChildNode(core)
        core.addChildNode(coreCore)
        
        update()
        idlize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func removeSelf() {
        removeAllConnected()
        removeFromParentNode()
        pointA.connectedObjects.remove(self)
        pointB.connectedObjects.remove(self)
    }
    
    func removeAllConnected() {
        let cObjects = connectedObjects
        for object in cObjects {
            object.removeSelf()
        }
        connectedObjects = Set<Object3D>()
    }
    
    func addConnectedObject(_ object: Triangle) {
        connectedObjects.insert(object)
        update()
    }
    
    public override func move(to point: SCNVector3) {
        position = point
        // update positions of points
        let delta = pointB.position - pointA.position
        let halfDelta = delta * 0.5
        pointA.move(to: point - halfDelta)
        pointB.move(to: point + halfDelta)
        // update
        update()
    }
    
    public override func update() {
        let delta = pointB.position - pointA.position
        let height = CGFloat(sqrt(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z))
        core.geometry = SCNCylinder(radius: 0.005, height: height)
        let halfDelta = delta * 0.5
        position = pointA.position + halfDelta
        core.eulerAngles.x = .pi / 2
        constraints = [SCNLookAtConstraint(target: pointB)]
        
        coreCore.geometry = SCNCylinder(radius: 0.003, height: height)
        
        switch state {
        case .idle:
            idlize()
        case .placing:
            idlize()
            
            let material = SCNMaterial()
            material.diffuse.contents = #colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 0.2022997359)
            material.blendMode = .add
            core.geometry?.materials = []
            for _ in 1...6 {
                core.geometry?.materials.append(material)
            }
        case .selected:
            idlize()
            
            let material = SCNMaterial()
            material.diffuse.contents = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.4008857835)
            material.blendMode = .alpha
            core.geometry?.materials = []
            for _ in 1...6 {
                core.geometry?.materials.append(material)
            }
        case .hidden:
            idlize()
            isHidden = true
        }
        
        // check for duplicates, and perform replacement
        /*
        if state != .placing {
            for child in workStation.guides.childNodes {
                if let otherLine = child as? Line {
                    if pointA === otherLine.pointA && pointB === otherLine.pointB {
                        if otherLine.state == .selected {
                            replaceBy(otherLine)
                        } else {
                            otherLine.replaceBy(self)
                        }
                    } else if pointA === otherLine.pointB && pointA === otherLine.pointA {
                        if otherLine.state == .selected {
                            replaceBy(otherLine)
                        } else {
                            otherLine.replaceBy(self)
                        }
                    }
                }
            }
        }
        */
    }
    
    public override func startPlacing(isNewObject: Bool) {
        placingAlong(isNewObject: isNewObject)
        // turn points to placing
        pointA.placingAlong(isNewObject: isNewObject)
        pointB.placingAlong(isNewObject: isNewObject)
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
    
    public func replaceBy(_ replaceLine: Line) {
        guard replaceLine !== self else { return }
        for connected in self.connectedObjects {
            // replace in connected triangle objects
            if let triangle = connected as? Triangle {
                if triangle.lineAB === self {
                    triangle.lineAB = replaceLine
                } else if triangle.lineBC === self {
                    triangle.lineBC = replaceLine
                } else {
                    triangle.lineAC = replaceLine
                }
                replaceLine.addConnectedObject(triangle)
            }
        }
        connectedObjects = Set<Object3D>()
        removeSelf()
        pointA.replaceBy(replaceLine.pointA)
        pointB.replaceBy(replaceLine.pointB)
    }
    
    override func idlize() {
        isHidden = false
        
        let material = SCNMaterial()
        material.diffuse.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25)
        material.blendMode = .alpha
        core.geometry?.materials = []
        for _ in 1...6 {
            core.geometry?.materials.append(material)
        }
    }
}
