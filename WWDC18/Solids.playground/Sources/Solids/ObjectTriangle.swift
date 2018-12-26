import SceneKit
import Foundation

public class Triangle: Object3D, HasDependency {
    public var pointA: Point { // self.position should be equal to pointA.position
        didSet { update() }
    }
    public var pointB: Point {
        didSet { update() }
    }
    public var pointC: Point {
        didSet { update() }
    }
    public var lineAB: Line {
        didSet { update() }
    }
    public var lineBC: Line {
        didSet { update() }
    }
    public var lineAC: Line {
        didSet { update() }
    }
    public var dependentObjects: [Object3D]
    
    public var color: UIColor {
        get {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    public var red: CGFloat {
        didSet {
            update()
            workStation.render()
        }
    }
    public var green: CGFloat {
        didSet {
            update()
            workStation.render()
        }
    }
    public var blue: CGFloat {
        didSet {
            update()
            workStation.render()
        }
    }
    public var alpha: CGFloat = 1 {
        didSet {
            update()
            workStation.render()
        }
    }
    public var previousColor: UIColor?
    
    var didSuperInit = false
    
    public init(from line: Line, to point: Point, in workStation: WorkStation) {
        lineAB = line
        pointA = line.pointA
        pointB = line.pointB
        pointC = point
        lineBC = Line(from: pointB, to: pointC, in: workStation)
        lineAC = Line(from: pointA, to: pointC, in: workStation)
        dependentObjects = [pointA, pointB, pointC, lineAB, lineBC, lineAC]
        
        red   = (CGFloat(arc4random() % 255) - 127) / 255 + 0.5
        green = (CGFloat(arc4random() % 255) - 127) / 255 + 0.5
        blue  = (CGFloat(arc4random() % 255) - 127) / 255 + 0.5
        
        super.init(in: workStation)
        didSuperInit = true
        
        workStation.addGuide(lineBC)
        workStation.addGuide(lineAC)
        
        for item in dependentObjects {
            if let i = item as? HasConnectedObjects {
                i.addConnectedObject(self)
            }
        }
        update()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func removeSelf() {
        for object in dependentObjects {
            if var obj = object as? HasConnectedObjects {
                obj.connectedObjects.remove(self)
            }
        }
        removeFromParentNode()
        workStation.render()
    }
    
    public override func move(to point: SCNVector3) {
        position = point
        // update positions of points
        let avgPosition = (pointA.position + pointB.position + pointC.position) * (1 / 3)
        let deltaA = pointA.position - avgPosition
        let deltaB = pointB.position - avgPosition
        let deltaC = pointC.position - avgPosition
        pointA.move(to: point + deltaA)
        pointB.move(to: point + deltaB)
        pointC.move(to: point + deltaC)
        lineAB.update()
        lineBC.update()
        lineAC.update()
        update()
    }
    
    override func idlize() {
        isHidden = false
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.blendMode = .alpha
        geometry?.materials = []
        for _ in 1...6 {
            geometry?.materials.append(material)
        }
    }
    
    public override func update() {
        dependentObjects = [pointA, pointB, pointC, lineAB, lineBC, lineAC]
        
        let avgPosition = (pointA.position + pointB.position + pointC.position) * (1 / 3)
        position = avgPosition
        
        let vertexA = pointA.position - position
        let vertexB = pointB.position - position
        let vertexC = pointC.position - position
        let source = SCNGeometrySource(vertices: [vertexA, vertexB, vertexC, vertexC, vertexB, vertexA])
        let indices: [Int32] = [0, 1, 2, 3, 4, 5]
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        geometry = SCNGeometry(sources: [source], elements: [element])
        
        switch state {
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
        
        if state != .placing { workStation.render() }
    }
    
    public override func startPlacing(isNewObject: Bool) {
        placingAlong(isNewObject: isNewObject)
        // turn all dependent objects to placing
        for object in dependentObjects {
            object.placingAlong(isNewObject: isNewObject)
        }
    }
    
    public func replaceBy(_ replaceTriangle: Triangle) {
        guard replaceTriangle !== self else { return }
        removeSelf()
    }
}
