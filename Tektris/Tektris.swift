//
//  Tektris.swift
//  Tektris
//
//  Created by Ara Atzuri on 1/11/17.
//  Copyright © 2017 hyalithus. All rights reserved.
//

let NumColumns = 10
let NumRows = 20

let StartingColumn = 4
let StartingRow = 0

let PreviewColumn = 12
let PreviewRow = 1

let PointsPerLine = 10
let LevelThreshold = 500

protocol TektrisDelegate {
    // Invoked when the current round of Tektris ends
    func gameDidEnd(tektris: Tektris)
    
    // Invoked after a new game has begun
    func gameDidBegin(tektris: Tektris)
    
    // Invoked when the falling shape has become part of the game board
    func gameShapeDidLand(tektris: Tektris)
    
    // Invoked when the falling shape has changed its location
    func gameShapeDidMove(tektris: Tektris)
    
    // Invoked when the falling shape has changed its location after being dropped
    func gameShapeDidDrop(tektris: Tektris)
    
    // Invoked when the game has reached a new level
    func gameDidLevelUp(tektris: Tektris)
}

class Tektris {
    var blockArray: Array2D<Block>
    var nextShape: Shape?
    var fallingShape: Shape?
    var delegate:TektrisDelegate?
    
    var score = 0
    var level = 1
    
    init() {
        fallingShape = nil
        nextShape = nil
        blockArray = Array2D<Block>(columns: NumColumns, rows: NumRows)
    }
    
    
    func beginGame() {
        if (nextShape == nil) {
            nextShape = Shape.random(startingColumn: PreviewColumn, startingRow: PreviewRow)
    }
        
        delegate?.gameDidBegin(tektris: self)
}

    func newShape() -> (fallingShape: Shape?, nextShape: Shape?) {
        fallingShape = nextShape
        nextShape = Shape.random(startingColumn: PreviewColumn, startingRow: PreviewRow)
        fallingShape?.moveTo(column: StartingColumn, row: StartingRow)
        
        guard detectIllegalPlacement() == false else {
            nextShape = fallingShape
            nextShape!.moveTo(column: PreviewColumn, row: PreviewRow)
            endGame()
            return(nil, nil)
        }
        
        return (fallingShape, nextShape)
    }
    
    
    func detectIllegalPlacement() -> Bool {
        guard let shape = fallingShape else {
            return false
        }
        
        for block in shape.blocks {
            if block.column < 0 || block.column >= NumColumns || block.row < 0 || block.row >= NumRows {
                return true
            } else if blockArray[block.column, block.row] != nil {
                return true
            }
        }
        
        return false
    }
    
    
    func letShapeFall() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.lowerShapeByOneRow()
        if detectIllegalPlacement() {
            shape.raiseShapeByOneRow()
            if detectIllegalPlacement() {
                endGame()
            } else {
                settleShape()
            }
            
        } else {
            delegate?.gameShapeDidMove(tektris: self)
            if detectTouch() {
                settleShape()
            }
        }
    }
    
    
    func dropShape() {
        guard let shape = fallingShape else {
            return
        }
        
        while detectIllegalPlacement() == false {
            shape.lowerShapeByOneRow()
        }
        
        shape.raiseShapeByOneRow()
        delegate?.gameShapeDidDrop(tektris: self)
    }
    
    
    func rotateShape() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.rotateClockwise()
        guard detectIllegalPlacement() == false else {
            shape.rotateCounterClockwise()
            return
        }
        
        delegate?.gameShapeDidMove(tektris: self)
    }
    
    
    func moveShapeLeft() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.shiftLeftByOneColumn()
        guard detectIllegalPlacement() == false else {
            shape.shiftRightByOneColumn()
            return
        }
        
        delegate?.gameShapeDidMove(tektris: self)
    }
    
    
    func moveShapeRight() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.shiftRightByOneColumn()
        guard detectIllegalPlacement() == false else {
            shape.shiftLeftByOneColumn()
            return
        }
        
        delegate?.gameShapeDidMove(tektris: self)
    }
    
    
    func settleShape() {
        guard let shape = fallingShape else {
            return
        }
        
        for block in shape.blocks {
            blockArray[block.column, block.row] = block
        }
        
        fallingShape = nil
        delegate?.gameShapeDidLand(tektris: self)
    }
    
    
    func detectTouch() -> Bool {
        guard let shape = fallingShape else {
            return false
        }
        
        for bottomBlock in shape.bottomBlocks {
            if bottomBlock.row == NumRows - 1 || blockArray[bottomBlock.column, bottomBlock.row + 1] != nil {
                return true
            }
        }
        return false
    }
    
    
    func endGame() {
        score = 0
        level = 1
        delegate?.gameDidEnd(tektris: self)
    }
    
    
    func removeCompletedLines() -> (linesRemoved: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>) {
        var removedLines = Array<Array<Block>>()
        
        for row in (1..<NumRows).reversed() {
            var rowOfBlocks = Array<Block>()
            
            for column in 0..<NumColumns {
                guard let block = blockArray[column, row] else {
                    continue
                }
                
                rowOfBlocks.append(block)
            }
            
            if rowOfBlocks.count == NumColumns {
                removedLines.append(rowOfBlocks)
                for block in rowOfBlocks {
                    blockArray[block.column, block.row] = nil
                }
            }
        }
        
        if removedLines.count == 0 {
            return([],[])
        }
        
        let pointsEarned = removedLines.count * PointsPerLine * level
        score += pointsEarned
        
        if score >= level * LevelThreshold {
            level += 1
            delegate?.gameDidLevelUp(tektris: self)
        }
        
        var fallenBlocks = Array<Array<Block>>()
        
        for column in 0..<NumColumns {
            var fallenBlocksArray = Array<Block>()
            
            for row in (1..<removedLines[0][0].row).reversed() {
                guard let block = blockArray[column, row] else {
                    continue
                }
                
                var newRow = row
                
                while (newRow < NumRows - 1 && blockArray[column, newRow + 1] == nil) {
                    newRow += 1
                }
                
                block.row = newRow
                blockArray[column, row] = nil
                blockArray[column, newRow] = block
                fallenBlocksArray.append(block)
            }
            
            if fallenBlocksArray.count > 0 {
                fallenBlocks.append(fallenBlocksArray)
            }
        }
        
        return (removedLines, fallenBlocks)
    }
    
    func removeAllBlocks() -> Array<Array<Block>> {
        var allBlocks = Array<Array<Block>>()
        
        for row in 0..<NumRows {
            var rowOfBlocks = Array<Block>()
            
            for column in 0..<NumColumns {
                guard let block = blockArray[column, row] else {
                    continue
                }
                
                rowOfBlocks.append(block)
                blockArray[column, row] = nil
            }
            
            allBlocks.append(rowOfBlocks)
        }
        
        return allBlocks
    }
    
}









