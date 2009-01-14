//
//  BreakpointHandle
//
//  Created by Shawn on 2008-01-10.
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

package edu.harvard.med.cadnano.drawing.handles {
    // flash
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;

    // misc
    import br.com.stimuli.string.printf;
    
    // cadnano
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.drawing.DrawVstrand; // for this.colors
    
    /*
    BreakpointHandle is a minimal extension of the Sprite class,
    allowing for simple handling of breakpoints.
    
    Each BreakpointHandle tracks its starting position.  When it is dragged,
    it informs DrawPath how far it moved so the Path data can be updated.
    */
    public class BreakpointHandle extends Sprite {
        private var lineThickness:Number = DrawPath.lineThickness;
        private var STAP_MAX:uint = DrawPath.STAP_MAX;
        private var STAP_MIN:uint = DrawPath.STAP_MIN;
        private var COLORSCAF:int = DrawVstrand.COLORSCAF; // blue
        private var COLORSTAP:int = DrawVstrand.COLORSTAP; // red
        private var baseWidth:int = DrawPath.baseWidth;
        private var halfbaseWidth:int = DrawPath.halfbaseWidth;
        public static var SCAFFOLD:String = "scaffold";
        public static var STAPLE:String = "staple";
        public static var LEFT_3PRIME:String  = "left3prime";
        public static var LEFT_5PRIME:String  = "left5prime";
        public static var RIGHT_3PRIME:String = "right3prime";
        public static var RIGHT_5PRIME:String = "right5prime";
        public var handletype:String = "BREAK";
        
        public var vstrand:Vstrand;
        public var type:String;
        public var strandType:String; // accessed by DrawPath.addScafCrossover()
        public var pos:int;  // accessed by DrawVstrand for sorting
        public var color:uint;
        
        private var drawPath:DrawPath;
        private var tokenArray:Array;
        private var boundary:Rectangle;
        private var startx:int;
        
        function BreakpointHandle(vstrand:Vstrand, strandType:String, yoffset:int, pos:int, type:String) {
            this.doubleClickEnabled = true;
            this.vstrand = vstrand;
            this.strandType = strandType;
            this.pos = pos;
            this.type = type;
            this.drawPath = this.vstrand.drawVstrand.drawPath;
            
            if (strandType == SCAFFOLD) {
                this.tokenArray = vstrand.scaf;
                this.color = COLORSCAF;
            } else if (strandType == STAPLE) {
                this.tokenArray = vstrand.stap;
                this.color = this.tokenArray[pos].color;
            }
            
            this.x = this.startx = pos*baseWidth;
            this.y = yoffset;
            // set initial drag boundary
            this.boundary = new Rectangle(this.x-pos*baseWidth, this.y, (tokenArray.length-1)*baseWidth, 0.1);
            this.drawBoxLines();
            
            this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
            this.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
        }
        
        private function drawBoxLines():void {
            this.graphics.clear();
            // draw white box as base
            this.graphics.beginFill(0xffffff,0);
            this.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.graphics.endFill();
            
            var borderR:Boolean = false;
            
            if (this.type == LEFT_3PRIME) {
                this.graphics.beginFill(this.color,1);
                this.graphics.lineStyle(0.25, this.color);
                this.graphics.moveTo(baseWidth,0);
                this.graphics.lineTo(0.25*baseWidth,halfbaseWidth);
                this.graphics.lineTo(baseWidth,baseWidth);
                this.graphics.endFill();
            } else if (this.type == LEFT_5PRIME) {
                this.graphics.beginFill(this.color,1);
                this.graphics.drawRect(0.25*baseWidth,0,0.75*baseWidth,baseWidth);
                this.graphics.endFill();
            } else if (this.type == RIGHT_3PRIME) {
                this.graphics.beginFill(this.color,1);
                this.graphics.lineStyle(0.25, this.color);
                this.graphics.moveTo(0,0);
                this.graphics.lineTo(0.75*baseWidth,halfbaseWidth);
                this.graphics.lineTo(0,baseWidth);
                this.graphics.endFill();
                borderR = true;
            } else if (this.type == RIGHT_5PRIME) {
                this.graphics.beginFill(this.color,1);
                this.graphics.drawRect(0,0,0.75*baseWidth,baseWidth);
                this.graphics.endFill();
                borderR = true;
            }
            
            // draw border
            if (borderR == true) {  // opens to the left
                this.graphics.lineStyle(0.25, 0xcccccc);
                this.graphics.moveTo(0,0);
                this.graphics.lineTo(baseWidth,0);
                this.graphics.lineTo(baseWidth,baseWidth);
                this.graphics.lineTo(0,baseWidth);
            } else { // border opens to the right
                this.graphics.lineStyle(0.25, 0xcccccc);
                this.graphics.moveTo(baseWidth,0);
                this.graphics.lineTo(0,0);
                this.graphics.lineTo(0,baseWidth);
                this.graphics.lineTo(baseWidth,baseWidth);
            }
        }
        
        /* Ligate a nick between two breakpoints.
         */
        private function clickHandler(event:MouseEvent):void {
            var remove:Boolean = false;
            
            if (event.shiftKey) {
                var i, len:int;
                var handles:Array;
                
                if (this.strandType == SCAFFOLD) {
                    handles = this.vstrand.drawVstrand.scafbreaks;
                } else {
                    handles = this.vstrand.drawVstrand.stapbreaks;
                }
                
                if (type == LEFT_3PRIME) {
                    for (i = 0; i < handles.length; i++) {
                        if (handles[i].pos == this.pos - 1) { // adjacent
                            if (handles[i].type == RIGHT_5PRIME) { // correct type
                                this.tokenArray[pos].next_strand = this.vstrand.number;
                                this.tokenArray[pos].next_pos = pos-1;
                                this.tokenArray[pos-1].prev_strand = this.vstrand.number;
                                this.tokenArray[pos-1].prev_pos = pos;
                                if (strandType == STAPLE) {
                                    this.drawPath.updateStapleColor(this.vstrand, pos, this.color);
                                    this.drawPath.updateStap(true);
                                } else {
                                    this.vstrand.drawVstrand.updateScaf();
                                }
                                remove = true;
                            }
                        }
                    }
                } else if (type == LEFT_5PRIME) {
                    for (i = 0; i < handles.length; i++) {
                        if (handles[i].pos == this.pos - 1) { // adjacent
                            if (handles[i].type == RIGHT_3PRIME) { // correct type
                                this.tokenArray[pos].prev_strand = this.vstrand.number;
                                this.tokenArray[pos].prev_pos = pos-1;
                                this.tokenArray[pos-1].next_strand = this.vstrand.number;
                                this.tokenArray[pos-1].next_pos = pos;
                                if (strandType == STAPLE) {
                                    this.drawPath.updateStapleColor(this.vstrand, pos, this.color);
                                    this.drawPath.updateStap(true);
                                } else {
                                    this.vstrand.drawVstrand.updateScaf();
                                }
                                remove = true;
                            }
                        }
                    }
                } else if (this.type == RIGHT_3PRIME) {
                    for (i = 0; i < handles.length; i++) {
                        if (handles[i].pos == this.pos + 1) { // adjacent
                            if (handles[i].type == LEFT_5PRIME) { // correct type
                                this.tokenArray[pos].next_strand = this.vstrand.number;
                                this.tokenArray[pos].next_pos = pos+1;
                                this.tokenArray[pos+1].prev_strand = this.vstrand.number;
                                this.tokenArray[pos+1].prev_pos = pos;
                                if (strandType == STAPLE) {
                                    this.drawPath.updateStapleColor(this.vstrand, pos, this.color);
                                    this.drawPath.updateStap(true);
                                } else {
                                    this.vstrand.drawVstrand.updateScaf();
                                }
                                remove = true;
                            }
                        }
                    }
                } else if (this.type == RIGHT_5PRIME) {
                    for (i = 0; i < handles.length; i++) {
                        if (handles[i].pos == this.pos + 1) { // adjacent
                            if (handles[i].type == LEFT_3PRIME) { // correct type
                                this.tokenArray[pos].prev_strand = this.vstrand.number;
                                this.tokenArray[pos].prev_pos = pos+1;
                                this.tokenArray[pos+1].next_strand = this.vstrand.number;
                                this.tokenArray[pos+1].next_pos = pos;
                                if (strandType == STAPLE) {
                                    this.drawPath.updateStapleColor(this.vstrand, pos, this.color);
                                    this.drawPath.updateStap(true);
                                } else {
                                    this.vstrand.drawVstrand.updateScaf();
                                }
                                remove = true;
                            }
                        }
                    }
                }
            } else if (event.altKey) {
                this.moveToBound();
            }
            
            if (remove) {
                this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
                this.removeEventListener(MouseEvent.CLICK, clickHandler);
            }
        }
        
        public function clearListeners():void {
            this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            this.removeEventListener(MouseEvent.CLICK, clickHandler);
        }
        
        public function moveToBound(redraw:Boolean=true):void {
            if (this.type == LEFT_3PRIME || this.type == LEFT_5PRIME) {
                this.x = this.boundary.left;
            } else {
                this.x = this.boundary.right;
            }
            this.refreshAfterMove(redraw);
        }
        
        private function mouseDownHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            startDrag(false,this.boundary);
            parent.setChildIndex(this, parent.numChildren - 1); // move to top
            this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        private function refreshAfterMove(redraw:Boolean=true):void {
            // update data
            var stapLength:int;
            var delta:int = (this.x-this.startx) / baseWidth;
            var loopDelta:int = 0;
            var skipDelta:int = 0;
            var i,t,vsNum:int;
            var s:String;
            var result:Boolean;
            vsNum = this.vstrand.number;
            
            if (this.type == LEFT_3PRIME) {
                if (delta > 0) { // remove bases
                    for (i = pos; i < pos+delta; i++) {
                        this.tokenArray[i].clearPrev();
                        this.tokenArray[int(i+1)].clearNext();
                        loopDelta -= this.vstrand.loop[i];
                        skipDelta += this.vstrand.skip[i];
                    }
                    delta = -delta;
                } else if (delta < 0) { // add bases
                    for (i = pos; i > pos+delta; i--) {
                        this.tokenArray[i].setNext(vsNum, i-1);
                        this.tokenArray[int(i-1)].setPrev(vsNum, i);
                        loopDelta += this.vstrand.loop[i];
                        skipDelta -= this.vstrand.skip[i];
                    }
                    delta = -delta;
                }
            } else if (this.type == LEFT_5PRIME) {
                if (delta > 0) { // remove bases
                    for (i = pos; i < pos+delta; i++) {
                        this.tokenArray[int(i+1)].clearPrev();
                        this.tokenArray[i].clearNext();
                        loopDelta -= this.vstrand.loop[i];
                        skipDelta += this.vstrand.skip[i];
                    }
                    delta = -delta;
                } else if (delta < 0) { // add bases
                    for (i = pos; i > pos+delta; i--) {
                        this.tokenArray[i].setPrev(vsNum, i-1);
                        this.tokenArray[int(i-1)].setNext(vsNum, i);
                        loopDelta += this.vstrand.loop[i];
                        skipDelta -= this.vstrand.skip[i];
                    }
                    delta = -delta;
                }
            } else if (this.type == RIGHT_3PRIME) { // add bases
                if (delta > 0) { // add bases
                    for (i = pos; i < pos+delta; i++) {
                        this.tokenArray[int(i+1)].setPrev(vsNum, i);
                        this.tokenArray[i].setNext(vsNum, i+1);
                        loopDelta += this.vstrand.loop[i];
                        skipDelta -= this.vstrand.skip[i];
                    }
                } else if (delta < 0) { // remove bases
                    for (i = pos; i > pos+delta; i--) {
                        this.tokenArray[i].clearPrev();
                        this.tokenArray[int(i-1)].clearNext();
                        loopDelta -= this.vstrand.loop[i];
                        skipDelta += this.vstrand.skip[i];
                    }
                }
            } else if (this.type == RIGHT_5PRIME) { // add bases
                if (delta > 0) { // add bases
                    for (i = pos; i < pos+delta; i++) {
                        this.tokenArray[i].setPrev(vsNum, i+1);
                        this.tokenArray[int(i+1)].setNext(vsNum, i);
                        loopDelta += this.vstrand.loop[i];
                        skipDelta -= this.vstrand.skip[i];
                    }
                } else if (delta < 0) { // remove bases
                    for (i = pos; i > pos+delta; i--) {
                        this.tokenArray[int(i-1)].clearPrev();
                        this.tokenArray[i].clearNext();
                        loopDelta -= this.vstrand.loop[i];
                        skipDelta += this.vstrand.skip[i];
                    }
                }
            }
            
            this.startx = this.x;
            this.pos = Math.round(this.x/baseWidth);
            
            delta = delta + loopDelta + skipDelta;
            if (delta != 0) {
                if (this.strandType == SCAFFOLD) {
                    if (redraw) {
                        this.vstrand.drawVstrand.updateScafBreakBounds();
                        this.vstrand.drawVstrand.drawScafLines();
                    }
                    // FIX: remove orphaned LoopHandles!
                } else {
                    this.tokenArray[pos].color = this.color;
                    this.vstrand.drawVstrand.updateStapBreakBounds();
                    result = this.drawPath.notifyLengthChange(delta, this.vstrand, this.pos, this.color);
                    this.tokenArray[i].highlight = result;
                    this.vstrand.drawVstrand.doStapRedraw = true;
                    this.drawPath.updateStap(true);
                }
            }
            if (redraw) {
                this.vstrand.drawVstrand.drawPath.makeActive(this.vstrand, this.pos);
            }
        }
        
        private function mouseUpHandler(event:MouseEvent):void {
            event.updateAfterEvent();
            stopDrag();
            // snap
            this.x = Math.round(this.x/baseWidth) * baseWidth;
            this.y = Math.round(this.y/baseWidth) * baseWidth;
            this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
            this.refreshAfterMove();
        }
        
        // Set draggable boundaries to a left and right position
        public function setBounds(lpos:int, rpos:int):void {
            var left:int = this.pos - lpos;
            var w:int = (rpos-lpos)*baseWidth;
            this.boundary = new Rectangle(this.x-left*baseWidth, this.y, w, 0.1);
        }
    }
}