//
//  CrossoverHandle
//
//  Created by Shawn on 2008-04-17.
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
    // debug
    import flash.system.System;
    
    // flash
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    // misc
    import br.com.stimuli.string.printf;
    import com.yahoo.astra.utils.*;
    import gs.TweenLite;
    
    // cadnano
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.drawing.DrawVstrand; // for colors
    
    
    /*
    CrossoverHandle is a minimal extension of the Sprite class,
    allowing for simple handling of potential and real crossovers.
    */
    public class CrossoverHandle extends Sprite {
        public var handletype:String = "CROSSOVER";
        private var lineThickness:Number = DrawPath.lineThickness;
        private var COLORSCAF:int = DrawVstrand.COLORSCAF; // blue
        private var COLORSTAP:int = DrawVstrand.COLORSTAP; // orange
        
        private var baseWidth:int = DrawPath.baseWidth;
        private var halfbaseWidth:int = DrawPath.halfbaseWidth;
        
        public static var SCAFFOLD:String = "scaffold";
        public static var STAPLE:String = "staple";
        public static var LEFT:String = "left";
        public static var RIGHT:String = "right";
        public static var LEFT_UP:String = "leftup";
        public static var LEFT_DOWN:String = "leftdown";
        public static var RIGHT_UP:String = "rightup";
        public static var RIGHT_DOWN:String = "rightdown";
        
        private var drawPath:DrawPath;
        public var vstrand:Vstrand;
        public var strandType:String; // staple or scaffold strand
        public var pos:int;  // accessed by DrawVstrand for sorting
        public var type:String;
        public var color:uint;
        
        public var tokenArray:Array;
        public var neighbor:CrossoverHandle;
        public var label:TextField;
        public var format:TextFormat;
        public var lineLayer:Sprite;
        
        private var boundary, rect:Rectangle;
        private var forced:Boolean = false;
        private var localpoint:Point = new Point();
        private var start:Point = new Point();
        private var end:Point = new Point();
        private var control:Point = new Point();
        private var cp:Point = new Point();
        private var xdiff, ydiff:Number;
        
        
        function CrossoverHandle(drawPath:DrawPath, vstrand:Vstrand, strandType:String, pos:int, type:String, forced:Boolean=false) {
            this.drawPath = drawPath;
            this.vstrand = vstrand;
            this.strandType = strandType;
            this.type = type;
            this.pos = pos;
            this.x = pos*baseWidth;
            if (strandType == SCAFFOLD) {
                this.y = (vstrand.number % 2)*baseWidth;
                this.tokenArray = vstrand.scaf;
                color = COLORSCAF;
            } else if (strandType == STAPLE) {
                this.y = ((vstrand.number + 1) % 2)*baseWidth;
                this.tokenArray = vstrand.stap;
                if (this.tokenArray[pos].color == null) {
                    color = COLORSTAP;
                } else {
                    color = uint(this.tokenArray[pos].color);
                }
            }
            
            this.forced = forced; // was the crossover drawn in manually?
            
            this.drawBoxLines();
            this.lineLayer = new Sprite();
            this.addChild(this.lineLayer);
            this.setChildIndex(lineLayer, this.numChildren-1); // move to top
            this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
        }
        
        /* Update CrossoverHandle with a new color and redraw all lines. */
        public function updateColor(color:uint):void {
            this.color = color;
            this.drawBoxLines();
            this.drawCrossoverLines();
        }
        
        /* Update pointer to vstrand token Array after extending vstrands. */
        public function refreshTokenArrayPointer():void {
            if (strandType == SCAFFOLD) {
                this.tokenArray = this.vstrand.scaf;
            } else if (strandType == STAPLE) {
                this.tokenArray = this.vstrand.stap;
            }
        }
        
        /* Draw lines that live inside the CrossoverHandle grid box. */
        private function drawBoxLines():void {
            this.graphics.clear();
            // draw white box as base
            this.graphics.beginFill(0xffffff,0);
            this.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.graphics.endFill();
            
            // update data and draw appropriate lines
            if (type == LEFT_UP) {
                this.graphics.lineStyle(lineThickness, this.color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                this.graphics.moveTo(-0.25,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,0);
            } else if (type == LEFT_DOWN) {
                this.graphics.lineStyle(lineThickness, this.color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                this.graphics.moveTo(-0.25,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,baseWidth);
            } else if (type == RIGHT_UP) {
                this.graphics.lineStyle(lineThickness, this.color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                this.graphics.moveTo(baseWidth+0.25,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,0);
            } else if (type == RIGHT_DOWN) {
                this.graphics.lineStyle(lineThickness, this.color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                this.graphics.moveTo(baseWidth+0.25,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,baseWidth);
            }
        }
        
        public function drawCrossoverLines():void {
            var g:Graphics = this.lineLayer.graphics;
            var xc:Number = 0.035; // control.x constant
            var yc:Number = 0.035; // control.y constant
            // draw line depending on user-defined distance threshold (FIX: threshold not implemented)
            g.clear();
            
            if (vstrand.number == neighbor.vstrand.number) {  // SPECIAL CASE 1: SAME STRAND
                if (this.x < neighbor.x) { // only draw from left
                    // if this and neighbor are on same vstrand, draw a horizontal line
                    if (this.type == LEFT_UP || this.type == RIGHT_UP) {
                        yc = -yc;
                        start.x = halfbaseWidth;
                        start.y = 0;
                        localpoint.x = neighbor.x+halfbaseWidth;
                        localpoint.y = neighbor.vstrand.drawVstrand.y;
                    } else {
                        start.x = halfbaseWidth;
                        start.y = baseWidth;
                        localpoint.x = neighbor.x+halfbaseWidth;
                        localpoint.y = neighbor.vstrand.drawVstrand.y+2*baseWidth;
                    }
                    end = DisplayObjectUtil.localToLocal(localpoint, this.drawPath, this);
                    control.x = (start.x + end.x)*0.5;
                    xdiff = end.x-start.x;
                    if (xdiff < 0) {xdiff = -xdiff;}
                    control.y = start.y+yc*xdiff;
                    g.lineStyle(lineThickness, this.color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                    g.moveTo(start.x, start.y);
                    g.curveTo(control.x, control.y, end.x, end.y);
                }
            } else if (vstrand.number % 2 == neighbor.vstrand.number % 2 &&  // SPECIAL CASE 2: SAME PARITY
                       vstrand.number < neighbor.vstrand.number) {  // only draw lines from lower-index vstrand
                if (this.type == LEFT_UP || this.type == RIGHT_UP) {
                    start.x = halfbaseWidth;
                    start.y = 0;
                } else {
                    start.x = halfbaseWidth;
                    start.y = baseWidth;
                }
                if (neighbor.type == LEFT_UP || neighbor.type == RIGHT_UP) {
                    localpoint.x = neighbor.x+halfbaseWidth;
                    localpoint.y = neighbor.vstrand.drawVstrand.y;
                } else {
                    localpoint.x = neighbor.x+halfbaseWidth;
                    localpoint.y = neighbor.vstrand.drawVstrand.y+2*baseWidth;
                }
                end = DisplayObjectUtil.localToLocal(localpoint, this.drawPath, this);
                ydiff = end.y-start.y;
                if (ydiff < 0) {ydiff = -ydiff;}
                control.x = start.x + xc*ydiff;
                control.y = (start.y + end.y)*0.5;
                g.lineStyle(lineThickness, this.color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                g.moveTo(start.x, start.y);
                g.curveTo(control.x, control.y, end.x, end.y);
            } else if (vstrand.number % 2 != neighbor.vstrand.number % 2 && 
                      vstrand.number % 2 == 0) {  // DEFAULT CASE: only draw lines from even to odd vstrand
                if (strandType == SCAFFOLD) {
                    if (this.type == LEFT_UP) {xc = -xc;}
                    start.x = halfbaseWidth;
                    start.y = 0;
                    localpoint.x = neighbor.x+halfbaseWidth;
                    localpoint.y = neighbor.vstrand.drawVstrand.y+2*baseWidth;
                } else if (strandType == STAPLE) {
                    if (this.type == LEFT_DOWN) {xc = -xc;}
                    start.x = halfbaseWidth;
                    start.y = baseWidth;
                    localpoint.x = neighbor.x+halfbaseWidth;
                    localpoint.y = neighbor.vstrand.drawVstrand.y;
                }
                end = DisplayObjectUtil.localToLocal(localpoint, this.drawPath, this);
                control.x = start.x + xc*Math.abs(end.y-start.y)
                control.y = (start.y + end.y)*0.5;
                g.lineStyle(lineThickness, this.color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
                g.moveTo(start.x, start.y);
                g.curveTo(control.x, control.y, end.x, end.y);
            }
        }
        
        public function init(editTokenArray:Boolean=true):void {
            var n:int = this.neighbor.vstrand.number;
            
            if (editTokenArray) {
                // update local data; install breakpoint if necessary
                if (type == LEFT_UP) {
                    this.tokenArray[pos].next_strand = n;
                    this.tokenArray[pos].next_pos = this.neighbor.pos;
                    // make breakpoint to the right
                    if (pos < this.tokenArray.length-1) {
                        if (this.tokenArray[int(pos+1)].prev_strand == this.vstrand.number &&
                            this.tokenArray[int(pos+1)].prev_pos == pos) {
                            this.tokenArray[int(pos+1)].prev_strand = -1;
                            this.tokenArray[int(pos+1)].prev_pos = -1;
                        }
                    }
                    // make breakpoint to the left if no sequence exists
                    if (pos > 0) {
                        if (this.tokenArray[int(pos-1)].prev_strand == -1 &&
                            this.tokenArray[int(pos-1)].next_strand == -1) {
                                this.tokenArray[pos].prev_strand = this.vstrand.number;
                                this.tokenArray[pos].prev_pos = pos-1;
                                this.tokenArray[int(pos-1)].next_strand = this.vstrand.number;
                                this.tokenArray[int(pos-1)].next_pos = pos;
                        }
                    }
                } else if (type == LEFT_DOWN) {
                    this.tokenArray[pos].prev_strand = n;
                    this.tokenArray[pos].prev_pos = this.neighbor.pos;
                    if (pos < this.tokenArray.length-1) {
                        if (this.tokenArray[int(pos+1)].next_strand == this.vstrand.number &&
                            this.tokenArray[int(pos+1)].next_pos == pos) {
                            this.tokenArray[int(pos+1)].next_strand = -1;
                            this.tokenArray[int(pos+1)].next_pos = -1;
                        }
                    }
                    // make breakpoint to the left if no sequence exists
                    if (pos > 0) {
                        if (this.tokenArray[int(pos-1)].next_strand == -1 &&
                            this.tokenArray[int(pos-1)].prev_strand == -1) {
                                this.tokenArray[pos].next_strand = this.vstrand.number;
                                this.tokenArray[pos].next_pos = pos-1;
                                this.tokenArray[int(pos-1)].prev_strand = this.vstrand.number;
                                this.tokenArray[int(pos-1)].prev_pos = pos;
                        }
                    }
                } else if (type == RIGHT_UP) {
                    this.tokenArray[pos].prev_strand = n;
                    this.tokenArray[pos].prev_pos = this.neighbor.pos;
                    if (pos > 0) {
                        if (this.tokenArray[int(pos-1)].next_strand == this.vstrand.number &&
                            this.tokenArray[int(pos-1)].next_pos == pos) {
                            this.tokenArray[int(pos-1)].next_strand = -1;
                            this.tokenArray[int(pos-1)].next_pos = -1;
                        }
                    }
                    // make breakpoint to the right if no sequence exists
                    if (pos < this.tokenArray.length-1) {
                        if (this.tokenArray[int(pos+1)].next_strand == -1 &&
                            this.tokenArray[int(pos+1)].prev_strand == -1) {
                                this.tokenArray[pos].next_strand = this.vstrand.number;
                                this.tokenArray[pos].next_pos = pos+1;
                                this.tokenArray[int(pos+1)].prev_strand = this.vstrand.number;
                                this.tokenArray[int(pos+1)].prev_pos = pos;
                        }
                    }
                } else if (type == RIGHT_DOWN) {
                    this.tokenArray[pos].next_strand = n;
                    this.tokenArray[pos].next_pos = this.neighbor.pos;
                    if (pos > 0) {
                        if (this.tokenArray[int(pos-1)].prev_strand == this.vstrand.number &&
                            this.tokenArray[int(pos-1)].prev_pos == pos) {
                            this.tokenArray[int(pos-1)].prev_strand = -1;
                            this.tokenArray[int(pos-1)].prev_pos = -1;
                        }
                    }
                    // make breakpoint to the right if no sequence exists
                    if (pos < this.tokenArray.length-1) {
                        if (this.tokenArray[int(pos+1)].next_strand == -1 &&
                            this.tokenArray[int(pos+1)].prev_strand == -1) {
                                this.tokenArray[pos].prev_strand = this.vstrand.number;
                                this.tokenArray[pos].prev_pos = pos+1;
                                this.tokenArray[int(pos+1)].next_strand = this.vstrand.number;
                                this.tokenArray[int(pos+1)].next_pos = pos;
                        }
                    }
                }
            }
            
            // draw number 
            this.label = new TextField();
            this.label.antiAliasType = AntiAliasType.ADVANCED;
            this.label.text = this.neighbor.vstrand.number.toString();
            this.label.autoSize = "left";
            this.format = new TextFormat();
            this.format.font = "Verdana";
            if (this.neighbor.vstrand.number < 100) {
                this.format.size = 8;
            } else {
                this.format.size = 5;
            }
            this.format.color = "0x333333";
            this.label.setTextFormat(format);
            this.label.mouseEnabled = false;
            this.addChild(label);
            this.rect = this.label.getRect(this);
            this.cp = new Point((this.rect.right-this.rect.left)*0.5,(this.rect.bottom-this.rect.top)*0.5);
            if (this.strandType == SCAFFOLD) {
                DynamicRegistration.move(this.label, this.cp, halfbaseWidth, -((vstrand.number % 2)*(-2)*baseWidth + halfbaseWidth));
            } else {
                DynamicRegistration.move(this.label, this.cp, halfbaseWidth, -(((vstrand.number + 1) % 2)*(-2)*baseWidth + halfbaseWidth));
            }
            this.drawCrossoverLines();
        }
        
        public function reNumber(transform:Object) {
            this.label.text = transform[this.label.text];
            this.label.setTextFormat(format);
            this.rect = this.label.getRect(this);
            this.cp = new Point((this.rect.right-this.rect.left)*0.5,(this.rect.bottom-this.rect.top)*0.5);
            if (this.strandType == SCAFFOLD) {
                DynamicRegistration.move(this.label, this.cp, halfbaseWidth, -((vstrand.number % 2)*(-2)*baseWidth + halfbaseWidth));
            } else {
                DynamicRegistration.move(this.label, this.cp, halfbaseWidth, -(((vstrand.number + 1) % 2)*(-2)*baseWidth + halfbaseWidth));
            }
        }
        
        // Set draggable boundaries to a left and right position
        public function setBounds(lpos:int, rpos:int):void {
            var left:int = this.pos - lpos;
            var w:int = (rpos-lpos)*baseWidth;
            this.boundary = new Rectangle(this.x-left*baseWidth,
                                          this.y, w, 0.1);
        }
        
        public function clearListeners():void {
            this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
        }
        
        private function mouseDownHandler(e:MouseEvent):void {
            if (e.shiftKey) {return;} // ignore input when user is trying to join breakpoints
            this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
        }
        
        /* Install breakpoints and remove CrossoverHandle pair
           from drawVstrands. */
        private function mouseUpHandler(e:MouseEvent):void {
            e.updateAfterEvent();
            this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
            this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            
            // update data to remove breakpoint
            if (this.type == LEFT_UP || this.type == RIGHT_DOWN) { // even
                this.tokenArray[this.pos].clearNext();
                this.neighbor.tokenArray[this.neighbor.pos].clearPrev();
            } else if (this.type == LEFT_DOWN || this.type == RIGHT_UP) {
                this.tokenArray[this.pos].clearPrev();
                this.neighbor.tokenArray[this.neighbor.pos].clearNext();
            }
            
            this.neighbor.vstrand.drawVstrand.removeCrossover(this.neighbor);
            this.vstrand.drawVstrand.removeCrossover(this);
            
            if (this.strandType == STAPLE) { // recolor staples
                this.drawPath.updateStapleColor(this.vstrand,
                                                this.pos,
                                                this.color);
                this.drawPath.updateStapleColor(this.neighbor.vstrand,
                                                this.neighbor.pos);
                this.drawPath.updateStap(true);
            } else {
                // have to update neighbor in the case of scaffold
                this.neighbor.vstrand.drawVstrand.update();
                this.vstrand.drawVstrand.update();
            }
        }
    }
}