import SpriteKit
import PlaygroundSupport

let height: CGFloat = 640
let width: CGFloat = height * 3 / 4
let size = CGSize(width: width, height: height)
let skView = SKView(frame: CGRect(x: 0, y: 0, width: width, height: height))
let widthHalf  = width / 2
let heightHalf = height / 2

PlaygroundPage.current.liveView = skView

skView.showsFPS            = true
skView.ignoresSiblingOrder = true

enum TileType {
    case path
    case wall
}

enum ButtonType {
    case titlePlay
    case buttonPause
    case buttonExit
}

enum AddonType {
    case star
    case litStar
    case specialAttackWindup
    case specialAttack
    case wallAttackWindup
}

enum SceneType {
    case SceneTitle
    case ScenePlay
}

let zOfButtons : CGFloat = 15
let zOfTiles   : CGFloat = 1
let zOfEffects : CGFloat = 2
let zOfHero    : CGFloat = 3
let zOfEnemy   : CGFloat = 4
let zOfShadows : CGFloat = 10

let keyCodeEsc  : UInt16 = 53
let keyCodeA    : UInt16 = 0
let keyCodeS    : UInt16 = 1
let keyCodeD    : UInt16 = 2
let keyCodeW    : UInt16 = 13
let keyCodeLeft : UInt16 = 123
let keyCodeRight: UInt16 = 124
let keyCodeDown : UInt16 = 125
let keyCodeUp   : UInt16 = 126

func createLabel(x: CGFloat, y: CGFloat, size: CGFloat, text: String) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: "AvenirNext-Regular")
    node.color = #colorLiteral(red: 0.474509805440903, green: 0.839215695858002, blue: 0.976470589637756, alpha: 1.0)
    node.verticalAlignmentMode = .center
    
    node.position  = CGPoint(x: x, y: y)
    node.fontSize  = size
    node.text      = text
    node.zPosition = zOfButtons
    
    return node
}

class Button : SKLabelNode {
    let type: ButtonType
    
    init(type: ButtonType, position: CGPoint) {
        self.type = type
        super.init()
        switch type {
        case .titlePlay:
            self.text                  = "Play"
            horizontalAlignmentMode    = .center
            self.verticalAlignmentMode = .center
        case .buttonPause:
            self.text                  = "Pause"
            horizontalAlignmentMode    = .left
            self.verticalAlignmentMode = .top
        case .buttonExit:
            self.text                  = "Exit"
            horizontalAlignmentMode    = .right
            self.verticalAlignmentMode = .top
        }
        self.text      = text
        self.fontSize  = height / 20
        self.fontName  = "AvenirNext-Regular"
        self.fontColor = #colorLiteral(red: 0.474509805440903, green: 0.839215695858002, blue: 0.976470589637756, alpha: 1.0)
        self.position  = position
        self.zPosition = zOfButtons
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func togglePause() {
        if type == .buttonPause {
            if skView.scene!.isPaused {
                text = "Resume"
            } else {
                text = "Pause"
            }
        }
    }
}

////////In-Game Properties////////

let allTiles = SKNode()

let squareSide = width / 6

// Tweak the numbers here for the right scrolling speed and acceleration
let initialSpeedDuration   = 0.8
let finalSpeedDuration     = 0.1
let speedIncreaseRateBase  = 0.09
let speedIncreaseRatePower = 0.09

let hero = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "hero.png")))

var score = 0

class Tile : SKNode {
    var node : SKSpriteNode
    var x    : Int
    var type : TileType
    
    init(type inputType: TileType, xCoordinate: (Int)) {
        type = inputType
        x    = xCoordinate
        
        switch type {
        case .path:
            node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "tileRoad.png")))
            node.zPosition = zOfTiles
        case .wall:
            node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "tileWall.png")))
            node.zPosition = zOfTiles + 0.1
        }
        
        super.init()
        
        node.size = CGSize(width: squareSide, height: squareSide)
        position  = CGPoint(x: CGFloat(xCoordinate - 1) * (squareSide) + (squareSide / 2), y: 0)
        
        addChild(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func turnIntoPath() {
        type = .path
        node.texture = SKTexture(image: #imageLiteral(resourceName: "tileRoad.png"))
        node.zPosition = zOfTiles
    }
    
    func turnIntoWall() {
        type = .path
        node.texture = SKTexture(image: #imageLiteral(resourceName: "tileWall.png"))
        node.zPosition = zOfTiles
    }
}

class AddOn : SKNode {
    var node : SKSpriteNode
    var type : AddonType
    
    init(type inputType: AddonType) {
        type = inputType
        
        switch type {
        case .star:
            node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "IMG_0041.PNG")))
            node.alpha = 0.5
        case .litStar:
            node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "IMG_0037.PNG")))
            node.alpha = 0.75
        case .specialAttack:
            node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "IMG_0039.PNG")))
            
        case .specialAttackWindup:
            node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "IMG_0032.PNG")))
        case .wallAttackWindup:
            node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "IMG_0035.PNG")))
        }
        
        super.init()
        set(type: inputType)
        
        node.zPosition = zOfEffects
        node.size = CGSize(width: squareSide, height: squareSide)
        addChild(node)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(type inputType: AddonType) {
        type = inputType
        switch type {
        case .star:
            node.texture = SKTexture(image: #imageLiteral(resourceName: "IMG_0041.PNG"))
            node.alpha = 0.5
            node.run(.repeatForever(.rotate(byAngle: 2 * .pi, duration: 4.0)))
        case .litStar:
            node.texture = SKTexture(image: #imageLiteral(resourceName: "IMG_0037.PNG"))
            node.alpha = 0.75
            node.run(.repeatForever(.rotate(byAngle: 2 * .pi, duration: 1.0)))
        case .specialAttack:
            node.texture = SKTexture(image: #imageLiteral(resourceName: "IMG_0039.PNG"))
            run(.sequence([
                .rotate(byAngle: 4 * .pi, duration: 0.5),
                .removeFromParent()
                ]))
            for i in (parent?.children)! {
                if i === hero {
                    effectRooted()
                    superpowerUse()
                    hero.run(.sequence([
                        .wait(forDuration: 0.5),
                        .run {
                            inAction = false
                        }
                        ]))
                }
            }
        case .specialAttackWindup:
            node.texture = SKTexture(image: #imageLiteral(resourceName: "IMG_0032.PNG"))
            run(.sequence([
                .rotate(byAngle: 2 * .pi, duration: 1.0),
                .run {
                    self.set(type: .specialAttack)
                }
                ]))
        case .wallAttackWindup:
            node.texture = SKTexture(image: #imageLiteral(resourceName: "IMG_0035.PNG"))
            run(.sequence([
                .fadeOut(withDuration: 1.0),
                .run {
                    (self.parent! as! Tile).turnIntoWall()
                },
                .removeFromParent()
                ]))
        }
    }
    
    func testStar() {
        if type == .star {
            set(type: .litStar)
            score += 1
        }
    }
}

////////In-Game Methods////////

var rowsGenerated = 0
var speedDuration = finalSpeedDuration + (initialSpeedDuration - finalSpeedDuration) / (Double(powf(Float(1 + speedIncreaseRateBase), Float(Double(rowsGenerated) * speedIncreaseRatePower))))

var lastRow   : SKNode?
var lastCombo : [Tile]?

func generateTiles() {
    let row = SKNode()
    var thisCombo : [Tile] = []
    
    if rowsGenerated % 2 == 0 {
        if lastCombo == nil { //Generate open first row
            for i in 1 ... 6 {
                thisCombo.append(Tile(type: .path, xCoordinate: i))
            }
        } else { //Generate row that connects from previous paths
            var lastPathCount  = 0
            var pathsAvailable = [1, 2, 3, 4, 5, 6]
            
            for i in lastCombo! {
                if i.type == .path {
                    lastPathCount += 1
                    thisCombo.append(Tile(type: .path, xCoordinate: i.x))
                    var removeIndex : Int?
                    
                    for j in 0 ..< pathsAvailable.count {
                        if i.x == pathsAvailable[j] {
                            removeIndex = j
                        }
                    }
                    
                    if let x = removeIndex {
                        pathsAvailable.remove(at: x)
                    }
                }
            }
            
            for i in pathsAvailable {
                if Int(arc4random() % 4) < lastPathCount {
                    thisCombo.append(Tile(type: .path, xCoordinate: i))
                }
            }
        }
    } else { //Generates paths that connect from previous paths
        var numberOfPaths = Int(arc4random() % 3) + 1
        var pathsAvailable = [1, 2, 3, 4, 5, 6]
        
        for i in lastCombo! {
            if i.type == .wall {
                var removeIndex : Int?
                
                for j in 0 ..< pathsAvailable.count {
                    if i.x == pathsAvailable[j] {
                        removeIndex = j
                    }
                }
                
                if let x = removeIndex {
                    pathsAvailable.remove(at: x)
                }
            }
        }
        
        if numberOfPaths > pathsAvailable.count {numberOfPaths = pathsAvailable.count}
        
        for _ in 1 ... numberOfPaths {
            let randomLocation = Int(arc4random() % UInt32(pathsAvailable.count))
            let addingCoordinate = pathsAvailable[randomLocation]
            pathsAvailable.remove(at: randomLocation)
            
            thisCombo.append(Tile(type: .path, xCoordinate: addingCoordinate))
        }
    }
    
    //Add addons
    
    if (rowsGenerated % 3 == 0) && (rowsGenerated != 0) {
        thisCombo[Int(arc4random() % UInt32(thisCombo.count))].addChild(AddOn(type: .star))
    }
    
    if rowsGenerated != 0 {
        for child in allTiles.children {
            for i in child.children {
                if let tile = i as? Tile {
                    if tile.type == .path {
                        let rand = arc4random() % 16
                        if rand == 0 {
                            tile.addChild(AddOn(type: .specialAttackWindup))
                        }
                    }
                }
            }
        }
    }
    
    //Add walls
    
    var wallsAvailable = [1, 2, 3, 4, 5, 6]
    for i in thisCombo {
        var removeIndex : Int?
        
        for j in 0 ..< wallsAvailable.count {
            if i.x == wallsAvailable[j] {
                removeIndex = j
            }
        }
        
        if let x = removeIndex {
            wallsAvailable.remove(at: x)
        }
    }
    
    for i in wallsAvailable {
        thisCombo.append(Tile(type: .wall, xCoordinate: i))
    }
    
    //Finalize
    
    lastCombo = thisCombo
    
    for tile in thisCombo {
        row.addChild(tile)
    }
    
    if let last = lastRow {
        row.position.y = last.position.y + squareSide
    }
    
    lastRow   = row
    rowsGenerated += 1
    
    allTiles.addChild(row)
    allTiles.position.y = 0
}

func createShadows(scene: SKScene) {
    let shadows = SKNode()
    scene.addChild(shadows)
    
    for i in 0 ... 1 {
        let childShadow = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "edgeOfHell.png")), size: CGSize(width: width, height: width * 0.25))
        childShadow.position  = CGPoint(x: widthHalf, y: heightHalf + widthHalf - width * CGFloat(i))
        childShadow.zPosition = zOfShadows
        childShadow.zRotation = CGFloat(.pi * Double(i))
        shadows.addChild(childShadow)
        
        let blackFrame = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 100))
        blackFrame.position = CGPoint(x: 0, y: heightHalf + widthHalf + childShadow.size.height / 2 - ((width + childShadow.size.height + 100) * CGFloat(i)))
        blackFrame.fillColor   = #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        blackFrame.strokeColor = #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        blackFrame.zPosition   = zOfShadows
        shadows.addChild(blackFrame)
    }
}

////////Special Modes////////

var superpowerOn = false
var combo        = 0

func testForSuperpower() {
    combo += 1
    if combo >= 4 {
        superpowerOn = true
        hero.texture = SKTexture(image: #imageLiteral(resourceName: "heroSwift.png"))
    }
}

func superpowerUse() -> Bool {
    let superpowerWasOn = superpowerOn
    superpowerOn = false
    combo = 0
    hero.texture = SKTexture(image: #imageLiteral(resourceName: "hero.png"))
    return superpowerWasOn
}

//////////////Effects//////////////

func effectGameStart() {
    let effect = createLabel(x: widthHalf, y: heightHalf, size: height / 16, text: "Use arrow/WASD keys to move.")
    let action = SKAction.sequence([
        .fadeIn(withDuration: 0.25),
        .wait(forDuration: 0.25),
        .fadeOut(withDuration: 0.5),
        .removeFromParent()
        ])
    
    effect.zPosition = zOfButtons
    
    skView.scene!.addChild(effect)
    effect.run(action)
}

func effectAddScore() {
    let effect = createLabel(x: 0, y: heightHalf / 24, size: height / 24, text: "+1 score")
    let action = SKAction.sequence([
        .fadeIn(withDuration: 0.1),
        .wait(forDuration: 0.1),
        .fadeOut(withDuration: 0.3),
        .removeFromParent()
        ])
    
    effect.zPosition = zOfButtons
    
    hero.addChild(effect)
    effect.run(action)
    effect.run(.moveBy(x: 0, y: height / 24, duration: 0.5))
}

func effectRooted() {
    let effect = createLabel(x: 0, y: heightHalf / 24, size: height / 24, text: "Rooted")
    let action = SKAction.sequence([
        .fadeIn(withDuration: 0.1),
        .wait(forDuration: 0.1),
        .fadeOut(withDuration: 0.3),
        .removeFromParent()
        ])
    
    effect.zPosition = zOfButtons
    
    hero.addChild(effect)
    effect.run(action)
    effect.run(.moveBy(x: 0, y: height / 24, duration: 0.5))
}

func effectSuperpowerGranted() {
    
}

func effectSuperpowerUsed() {
    
}

////////Sliding Controls////////

var inAction = false

func slideTest(xShift: CGFloat, yShift: CGFloat) {
    var duration = 0.05
    if superpowerOn {
        duration = 0.02
    }
    
    let moveHalf = SKAction.move(to: CGPoint(x: xShift / 2, y: yShift / 2), duration: duration)
    
    let moveBack = SKAction.sequence([
        .move(to: CGPoint(x: 0, y: 0), duration: duration),
        .wait(forDuration: 0.1),
        .run {
            superpowerUse()
            inAction = false
        }])
    
    let determine = SKAction.run {
        let determineX = (hero.parent?.position.x)! + xShift
        let determineY = (hero.parent?.parent?.position.y)! + yShift
        let nodes      = allTiles.nodes(at: CGPoint(x: determineX, y: determineY))
        
        var determined = false
        
        for node in nodes {
            if !determined {
                if let tile = node as? Tile {
                    let moveFull = SKAction.sequence([
                        .move(to: CGPoint(x: xShift, y: yShift), duration: 0.1),
                        .run {
                            testForSuperpower()
                            hero.removeFromParent()
                            tile.addChild(hero)
                            hero.position = CGPoint(x: 0, y: 0)
                            
                            var stunned = false
                            for child in (hero.parent?.children)! {
                                if let addOn = child as? AddOn {
                                    switch addOn.type {
                                    case .star:
                                        effectAddScore()
                                        addOn.testStar()
                                    case .specialAttack: stunned = true
                                    default: break
                                    }
                                }
                            }
                            if stunned {
                                if superpowerUse() {
                                    effectRooted()
                                    hero.run(.sequence([
                                        .wait(forDuration: 0.5),
                                        .run {
                                            inAction = false
                                        }
                                        ]))
                                } else {
                                    effectRooted()
                                    hero.run(.sequence([
                                        .wait(forDuration: 1.0),
                                        .run {
                                            inAction = false
                                        }
                                        ]))
                                }
                            } else {
                                inAction = false
                            }
                        }])
                    
                    if tile.type == .path {
                        hero.run(moveFull)
                    } else {
                        if superpowerUse() {
                            tile.turnIntoPath()
                            hero.run(moveFull)
                        } else {
                            hero.run(moveBack)
                        }
                    }
                    determined = true
                }
            }
        }
        
        if !determined {
            superpowerUse()
            hero.run(moveBack)
        }
    }
    
    hero.run(.sequence([moveHalf, determine]))
}

func slide(begin: CGPoint, end: CGPoint) {
    if !inAction {
        let xDiff = end.x - begin.x
        let yDiff = end.y - begin.y
        let angle = Double(atan2(yDiff, xDiff))
        
        inAction = true
        
        switch angle {
        case -(3 * .pi / 4) ..<    -(.pi / 4): /* Down  */ slideTest(xShift: 0, yShift: -squareSide)
        case     -(.pi / 4) ..<     (.pi / 4): /* Right */ slideTest(xShift: squareSide, yShift: 0)
        case      (.pi / 4) ..< (3 * .pi / 4): /* Up    */ slideTest(xShift: 0         , yShift: squareSide)
        default                              : /* Left  */ slideTest(xShift: -squareSide, yShift: 0)
        }
    }
}

////////////Handling Input////////////

var currentScene = SceneType.SceneTitle
var tappedButton       : ButtonType?
var tappedButtonNode   : Button?
var previousInputPoint : CGPoint?

func inputBegan(event: NSEvent) {
    let touchPoint = event.location(in: skView.scene!)
    
    for touchNode in (skView.scene?.nodes(at: touchPoint))! {
        if let touchedButton = touchNode as? Button {
            tappedButton     = touchedButton.type
            tappedButtonNode = touchedButton
            tappedButtonNode?.alpha = 0.5
            return
        }
    }
    
    previousInputPoint = touchPoint
}

func inputEnded(event: NSEvent) {
    let touchPoint = event.location(in: skView.scene!)
    
    tappedButtonNode?.alpha = 1.0
    
    for touchNode in (skView.scene?.nodes(at: touchPoint))! {
        if let touchedButton = touchNode as? Button {
            if touchedButton.type == tappedButton {
                switch touchedButton.type {
                case .titlePlay:   skView.presentScene(ScenePlay(size: size))
                    
                case .buttonPause:
                    skView.scene?.isPaused = !(skView.scene?.isPaused)!
                    touchedButton.togglePause()
                    
                case .buttonExit:  skView.presentScene(SceneTitle(size: size))
                }
            }
            return
        }
    }
    
    if let begin = previousInputPoint {
        slide(begin: begin, end: touchPoint)
    }
    
    tappedButtonNode   = nil
    tappedButton       = nil
    previousInputPoint = nil
}

//////////////Scenes//////////////

func togglePause() {
    for child in (skView.scene?.children)! {
        if let button = child as? Button {
            button.togglePause()
        }
    }
}

func slideWithKeys(xShift: CGFloat, yShift: CGFloat) {
    if !inAction {
        inAction = true
        slideTest(xShift: xShift, yShift: yShift)
    }
}

class SceneTitle : SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        
        currentScene = .SceneTitle
        scaleMode    = .aspectFill
        
        backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
    
        addChild(Button(type: .titlePlay, position: CGPoint(x: widthHalf, y: height * 0.3)))
        
        let title = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "Untitled 7.png")))
        title.size = CGSize(width: width * 0.7, height: width * 0.525)
        title.position = CGPoint(x: widthHalf, y: height * 0.65)
        addChild(title)
        
        createShadows(scene: self)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        inputBegan(event: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        inputEnded(event: event)
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case keyCodeEsc: togglePause()
        default: break
        }
    }
}

//------------------------//

func gameSetup() {
    allTiles.removeAllChildren()
    allTiles.removeAllActions()
    hero.removeAllActions()
    
    rowsGenerated = 0
    speedDuration = finalSpeedDuration + (initialSpeedDuration - finalSpeedDuration) / (Double(powf(Float(1 + speedIncreaseRateBase), Float(Double(rowsGenerated) * speedIncreaseRatePower))))
    
    lastRow   = nil
    lastCombo = nil
    
    inAction     = false
    superpowerOn = false
    combo        = 0
    
    hero.texture   = SKTexture(image: #imageLiteral(resourceName: "hero.png"))
    hero.size      = CGSize(width: squareSide, height: squareSide)
    hero.position  = CGPoint(x: 0, y: 0)
    hero.zPosition = zOfHero
    
    score = 0
    
    for _ in 1 ... 5 {
        lastCombo     = nil
        rowsGenerated = 0
        
        generateTiles()
    }
    for _ in 6 ... 9 {
        generateTiles()
    }
    
    allTiles.children[4].children[3].addChild(hero)
    
    effectGameStart()
    
    allTiles.run(.repeatForever(.sequence([.move(to: CGPoint(x: 0, y: -squareSide), duration: speedDuration), .run {
        allTiles.children[0].removeFromParent()
        for child in allTiles.children {
            child.position.y -= squareSide
        }
        generateTiles()
        speedDuration = finalSpeedDuration + (initialSpeedDuration - finalSpeedDuration) / (Double(powf(Float(1 + speedIncreaseRateBase), Float(Double(rowsGenerated) * speedIncreaseRatePower))))
        if let heroY = hero.parent?.parent?.position.y {
            if heroY <= 0 * squareSide {
                skView.presentScene(SceneOver(victory: false, size: size))
            }
        }
        }])))
    
}

class ScenePlay : SKScene {
    let scoreLabel : SKLabelNode
    
    override init(size: CGSize) {
        scoreLabel = createLabel(x: widthHalf, y: height - 20, size: height / 16, text: "Score: 0")
        scoreLabel.verticalAlignmentMode = .top
        
        super.init(size: size)
        currentScene = .ScenePlay
        scaleMode    = .aspectFill
        
        gameSetup()
        
        createShadows(scene: self)
        
        addChild(Button(type: .buttonPause, position: CGPoint(x: 20, y: height - 20)))
        addChild(Button(type: .buttonExit,  position: CGPoint(x: width - 20, y: height - 20)))
        addChild(scoreLabel)
        addChild(allTiles)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        inputBegan(event: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        inputEnded(event: event)
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case keyCodeA    : slideWithKeys(xShift: -squareSide, yShift: 0)
        case keyCodeLeft : slideWithKeys(xShift: -squareSide, yShift: 0)
        case keyCodeD    : slideWithKeys(xShift:  squareSide, yShift: 0)
        case keyCodeRight: slideWithKeys(xShift:  squareSide, yShift: 0)
        case keyCodeW    : slideWithKeys(xShift: 0, yShift:  squareSide)
        case keyCodeUp   : slideWithKeys(xShift: 0, yShift:  squareSide)
        case keyCodeS    : slideWithKeys(xShift: 0, yShift: -squareSide)
        case keyCodeDown : slideWithKeys(xShift: 0, yShift: -squareSide)
        case keyCodeEsc: togglePause()
        default: break
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        scoreLabel.text = "Score: \(score)"
    }
    
    deinit {
        allTiles.removeFromParent()
        hero.removeFromParent()
    }
}

//------------------------//

class SceneOver : SKScene {
    init(victory: Bool, size: CGSize) {
        super.init(size: size)
        
        if victory {
            backgroundColor = #colorLiteral(red: 0.10196078568697, green: 0.278431385755539, blue: 0.400000005960464, alpha: 1.0)
            addChild(createLabel(x: widthHalf, y: height * 0.6, size: height / 10, text: "Victory!"))
            addChild(createLabel(x: widthHalf, y: heightHalf, size: height / 20, text: "Score: \(score)"))
        } else {
            backgroundColor = #colorLiteral(red: 0.317647069692612, green: 0.0745098069310188, blue: 0.0274509806185961, alpha: 1.0)
            addChild(createLabel(x: widthHalf, y: height * 0.6, size: height / 16, text: "You have perished."))
            addChild(createLabel(x: widthHalf, y: heightHalf, size: height / 20, text: "Score: \(score)"))
        }
        
        let exitButton = Button(type: .buttonExit, position: CGPoint(x: widthHalf, y: height * 0.4))
        exitButton.horizontalAlignmentMode = .center
        addChild(exitButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        inputBegan(event: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        inputEnded(event: event)
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case keyCodeEsc: togglePause()
        default: break
        }
    }
}

//------------------------//

skView.presentScene(SceneTitle(size: size))


