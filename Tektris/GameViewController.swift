//
//  GameViewController.swift
//  Tektris
//
//  Created by Ara Atzuri on 1/11/17.
//  Copyright © 2017 hyalithus. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, TektrisDelegate, UIGestureRecognizerDelegate {
    
    var scene: GameScene!
    var tektris:Tektris!
    var panPointReference:CGPoint?
    

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        
        // Create and configure the scene.
        scene = GameScene(size:skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        scene.tick = didTick
        
        tektris = Tektris()
        tektris.delegate = self
        tektris.beginGame()
        
        
        // Present the scene.
        skView.presentScene(scene)
        
/*        
         scene.addPreviewShapeToScene(shape: tektris.nextShape!) {
            self.tektris.nextShape?.moveTo(column: StartingColumn, row: StartingRow)
            self.scene.movePreviewShape(shape: self.tektris.nextShape!) {
                let nextShapes = self.tektris.newShape()
                self.scene.startTicking()
                self.scene.addPreviewShapeToScene(shape: nextShapes.nextShape!){}
            }
        }
*/
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        tektris.rotateShape()
    }
    
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translation(in: self.view)
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocity(in: self.view).x > CGFloat(0) {
                    tektris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    tektris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .began {
            panPointReference = currentPoint
        }
    }
    
    
    @IBAction func didSwipe(_ sender: UISwipeGestureRecognizer) {
        tektris.dropShape()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        
        return true
    }

    
    func didTick() {
        tektris.letShapeFall()
    }
    
    
    func nextShape() {
        let newShapes = tektris.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        
        self.scene.addPreviewShapeToScene(shape: newShapes.nextShape!){}
        self.scene.movePreviewShape(shape: fallingShape) {
            self.view.isUserInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    
    func gameDidBegin(tektris: Tektris) {
        levelLabel.text = "\(tektris.level)"
        scoreLabel.text = "\(tektris.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if tektris.nextShape != nil && tektris.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(shape: tektris.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(tektris: Tektris) {
        view.isUserInteractionEnabled = false
        scene.stopTicking()
        
        scene.playSound(sound: "Sounds/gameover.mp3")
        scene.animateCollapsingLines(linesToRemove: tektris.removeAllBlocks(), fallenBlocks: tektris.removeAllBlocks()) {
            tektris.beginGame()
        }
    }
    
    
    func gameDidLevelUp(tektris: Tektris) {
        levelLabel.text = "\(tektris.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound(sound: "Sounds/levelup.mp3")
    }
    
    
    func gameShapeDidDrop(tektris: Tektris) {
        scene.stopTicking()
        scene.redrawShape(shape: tektris.fallingShape!) {
            tektris.letShapeFall()
        }
        scene.playSound(sound: "Sounds/drop.mp3")
    }
    
    
    func gameShapeDidLand(tektris: Tektris) {
        scene.stopTicking()
        
        self.view.isUserInteractionEnabled = false
        let removedLines = tektris.removeCompletedLines()
        
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(tektris.score)"
            scene.animateCollapsingLines(linesToRemove: removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                self.gameShapeDidLand(tektris: tektris)
            }
            scene.playSound(sound: "Sounds/bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    
    func gameShapeDidMove(tektris: Tektris) {
        scene.redrawShape(shape: tektris.fallingShape!) {}
    }
    
}

















