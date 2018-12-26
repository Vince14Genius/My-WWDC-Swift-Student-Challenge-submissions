import SpriteKit
import PlaygroundSupport

public class MenuScene : SKScene {
    var solidsButton: SKNode?
    var isClickingOnButton = false
    
    public override func didMove(to view: SKView) {
        let nodes = childNode(withName: "others")!.children
        let effectNode = SKEffectNode()
        for node in nodes {
            node.removeFromParent()
            effectNode.addChild(node)
        }
        effectNode.filter = CIFilter(name: "CIGaussianBlur",
                               withInputParameters: ["inputRadius": 36])
        effectNode.shouldEnableEffects = true
        addChild(effectNode)
        
        solidsButton = childNode(withName: "IconSolids")
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if atPoint(touch.location(in: self)) === childNode(withName: "IconSolids")! {
                isClickingOnButton = true
                solidsButton?.alpha = 0.6
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if atPoint(touch.location(in: self)) === childNode(withName: "IconSolids")! {
                Controller.showARScene(.solids, in: PlaygroundPage.current)
            }
        }
        isClickingOnButton = false
        solidsButton?.alpha = 1
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isClickingOnButton = false
        solidsButton?.alpha = 1
    }
}

