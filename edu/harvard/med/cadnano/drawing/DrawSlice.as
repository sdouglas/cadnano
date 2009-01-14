//
//  DrawSlice
//
//  Created by Shawn on 2007-10-18.
//

/*
The MIT License

Copyright (c) 2008 Shawn M. Douglas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

http://www.opensource.org/licenses/mit-license.php
*/

package edu.harvard.med.cadnano.drawing {
    // flash
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    
    // cadnano
    import edu.harvard.med.cadnano.*;
    import edu.harvard.med.cadnano.data.SliceNode;
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.drawing.*;
    
    // misc 3rd party
    import com.yahoo.astra.fl.managers.AlertManager;
    
    /*
    DrawSlice handles the high-level organization and drawing of slices.
    SliceNode data is accessed by looping through the drawNodeArray,
    which is an Object() that I treat as a hash, with "row,col" coordinates
    as keys and pointers to SliceNodes as values.
    */
    public class DrawSlice extends Sprite {
        
        // Bookkeeping
        public var rows:int; // accessed by Svg.as
        public var cols:int; // accessed by Svg.as
        public var drawNodeArray:Object = new Object(); // accessed by Svg.as
        private var evens:int = -2;
        private var odds:int = -1;
        public var slice:Slice; // accessed by Svg.as
        private var path:Path;
        private var drawPath:DrawPath;
        
        function DrawSlice(slice:Slice, rows:int, cols:int, radius:int, path:Path, drawPath:DrawPath) {
            var node:DrawNode;
            var index:String;
            
            this.slice = slice;
            this.rows = rows;
            this.cols = cols;
            this.path = path;
            this.drawPath = drawPath;
            this.drawPath.drawSlice = this;
            
            for (var col:int = 0; col < cols; col++)
            {
                for (var row:int = 0; row < rows; row++)
                {
                    // create node and setup handlers
                    node = new DrawNode(row, col, radius);
                    addChild(node);
                    node.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
                    node.addEventListener(MouseEvent.MOUSE_OUT,  onMouseOut);
                    node.addEventListener(MouseEvent.CLICK, onClick);
                    
                    // add new node to the hash
                    index = row + "," + col;
                    drawNodeArray[index] = node;
                }
            }
        }
        
        public function resetCounters(even:int, odd:int):void {
            evens = even;
            odds = odd;
        }
        
        public function resetSliceNodes():void {
            var index:String;
            var sliceNode:SliceNode;
            for (var col:int = 0; col < this.cols; col++)
            {
                for (var row:int = 0; row < this.rows; row++)
                {
                    index = row + "," + col;
                    sliceNode = this.slice.sliceHash[index];
                    sliceNode.marked = false;
                    sliceNode.number = -1;
                    sliceNode.vstrand = null;
                    sliceNode.drawNode.refreshNode();
                }
            }
        }
        
        public function deleteLast():void {
            var deleteIt:Boolean = true;
            
            // do nothing if there are no vstrands
            if (this.path.vsList.size == 1) {
                return;
            }
            
            // otherwise find last helix
            var lastVs:Vstrand = this.path.vsList.tail.data;
            
            // find if it has no scaffold xovers
            for (var pos:int = 0; pos < lastVs.scaf.length; pos++) {
                if (lastVs.hasScafXover(pos) || lastVs.hasStapXover(pos)) {
                    deleteIt = false;
                    AlertManager.createAlert(this.parent.parent,
                                             "To delete the highest-numbered helix,\nyou must first manually remove all\nscaffold and staple crossovers to that helix.\n\nUse the re-num tool if you need to\n delete a lower-numbered helix.",
                                             "Warning: Delete-Last Button",
                                             null,
                                             null,
                                             null,
                                             true,
                                             {textColor:0x000000},
                                             TextFieldType.DYNAMIC,
                                             null);
                    return;
                }
            }
            
            if (deleteIt) {
                // find the index in the slice 
                var num:int = lastVs.number;
                var index:String;
                for (var col:int = 0; col < cols; col++) {
                    for (var row:int = 0; row < rows; row++) {
                        if (this.slice.sliceHash[row + "," + col].number == num) {
                            index = row + "," + col;
                        }
                    }
                }
                
                // delete the vstrand from sliceHash
                var sliceNode:SliceNode = this.slice.sliceHash[index];
                if (sliceNode.number % 2 == 0) { // reset helix numbering
                    evens = sliceNode.number - 2;
                } else {
                    odds = sliceNode.number - 2;
                }
                sliceNode.marked = false;
                sliceNode.number = -1;
                sliceNode.vstrand = null;
                sliceNode.drawNode.refreshNode();
                this.path.drawPath.removeLastVstrand();
                
                // update DrawSlice
                this.update();
            }
        }
        
        // update nodes with new data
        public function update(radius:int=-1):void {
            var sliceHash:Object = this.slice.sliceHash;  // FIX (redundant)
            var index:String;
            var sliceNode:SliceNode;
            var drawNode:DrawNode;
            var c:int = this.drawPath.currentSlice;
            
            /* 
            Loop through sliceList positions, and update the status
            for corresponding node positions
            */
            for (var col:int = 0; col < this.cols; col++)
            {
                for (var row:int = 0; row < this.rows; row++)
                {
                    index = row + "," + col;
                    sliceNode = sliceHash[index];
                    drawNode = drawNodeArray[index];
                    drawNode.sliceNode = sliceNode; // point at sliceNode
                    sliceNode.drawNode = drawNode;
                    
                    if (radius != -1) { // only update radius if resizing
                        drawNode.updateRadius(radius);
                        if (radius > 5) {
                            drawNode.linewidth = 1;
                        } else {
                            drawNode.linewidth = 0.5;
                        }
                    }
                    
                    if (sliceNode.vstrand != null) {
                        if (sliceNode.vstrand.scaf[c].prev_strand != -1 ||
                            sliceNode.vstrand.scaf[c].next_strand != -1) {
                            sliceNode.marked = true;
                        } else {
                            sliceNode.marked = false;
                        }
                    }
                    
                    drawNode.refreshNode();
                }
            }
        }
        
        public function reCenter():void {
            var index:String;
            var drawNode:DrawNode;
            for (var col:int = 0; col < this.cols; col++)
            {
                for (var row:int = 0; row < this.rows; row++)
                {
                    index = row + "," + col;
                    drawNode = drawNodeArray[index];
                    drawNode.reCenterNumber();
                }
            }
        }
        
        private function onMove(e:MouseEvent):void {
            e.target.hover();
        }
        
        private function onMouseOut(e:MouseEvent):void {
            e.target.unhover();
        }
        
        /**
         * onClick handles toggling of nodes, assigning of numbers
         * - newly clicked node notifies path to add vstrand
         * - previously clicked node notifies path to modify bases
         **/
        private function onClick(event:MouseEvent):void {
            var node:SliceNode = event.target.sliceNode;
            
            if (!node.marked) { // newly marked
                node.marked = true; // toggle
                
                if (node.number == -1) { // previously un-numbered 
                    
                    if (node.parity == 1) { 
                        node.number = odds += 2;
                    } else {
                        node.number = evens += 2;
                    }
                    path.addHelix(node);
                    
                    // install Vstrand neighbor relationships
                    if (node.p0neighbor != null && node.p0neighbor.number != -1) {
                        path.pairHelices(node.vstrand, node.p0neighbor.vstrand, 0);
                    }
                    if (node.p1neighbor != null && node.p1neighbor.number != -1) {
                        path.pairHelices(node.vstrand, node.p1neighbor.vstrand, 1);
                    }
                    if (node.p2neighbor != null && node.p2neighbor.number != -1) {
                        path.pairHelices(node.vstrand, node.p2neighbor.vstrand, 2);
                    }
                } else { // update existing
                    if (event.shiftKey) {
                        path.addStapleBases(this.drawPath.currentSlice,node.vstrand);
                    } else {
                        path.addBases(this.drawPath.currentSlice,node.vstrand);
                    }
                    
                    node.vstrand.drawVstrand.update();
                }
            } else { // scaffold already present
                if (node.number != -1) { // previously un-numbered 
                    if (event.shiftKey) {
                        path.addStapleBases(this.drawPath.currentSlice,node.vstrand);
                        node.vstrand.drawVstrand.update();
                    }
                }
            }
            
            event.target.refreshNode();
        }
    }
}
