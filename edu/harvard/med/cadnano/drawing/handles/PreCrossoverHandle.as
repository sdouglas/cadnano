//
//  PreCrossoverHandle
//
//  Created by Shawn on 2008-04-18.
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
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    // misc
    import br.com.stimuli.string.printf;
    import com.yahoo.astra.utils.DynamicRegistration;
    
    // cadnano
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.drawing.DrawPath;
    import edu.harvard.med.cadnano.drawing.DrawVstrand; // for colors
    
    /*
    PreCrossoverHandle is a minimal extension of the Sprite class,
    allowing for simple handling of potential and real crossovers.
    
    */
    public class PreCrossoverHandle extends Sprite {
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
        public var strandType:String; // accessed by DrawPath.addScafCrossover
        public var type:String;
        public var pos:int;  // accessed by DrawVstrand for sorting
        public var txt:int;
        public var label:TextField;
        
        public var tokenArray:Array;
        private var color:uint;
        
        private var format:TextFormat;
        private var bg:Sprite;
        
        public var neighbor:PreCrossoverHandle;

        function PreCrossoverHandle() {
            this.alpha = 0.5; // potential crossover
            this.bg = new Sprite();
            this.bg.alpha = 0;
            this.addChild(bg);
            this.setChildIndex(this.bg, 0);
            this.bg.graphics.beginFill(0xffffff,1); // draw white box as base
            this.bg.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.bg.graphics.endFill();
            
            this.label = new TextField();
            this.label.antiAliasType = AntiAliasType.ADVANCED;
            this.label.autoSize = "left";
            this.label.mouseEnabled = false;
            this.format = new TextFormat();
            this.format.font = "Verdana";
            this.format.color = "0xaaaaaa";
            this.addChild(label);
            
            this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
        }
        
        public function init(drawPath:DrawPath, vstrand:Vstrand, strandType:String, pos:int, lfrt:String, txt:int) {
            this.drawPath = drawPath;
            this.vstrand = vstrand;
            this.strandType = strandType;
            this.pos = pos;
            this.txt = txt;
            this.x = pos*baseWidth;
            
            var result:int = 0;
            if (strandType == SCAFFOLD) {
                this.tokenArray = vstrand.scaf;
                color = COLORSCAF;
            } else if (strandType == STAPLE) {
                this.tokenArray = vstrand.stap;
                color = COLORSTAP;
                result = 1;
            }
            
            if (vstrand.number % 2 == result) {
                this.y = vstrand.drawVstrand.y - baseWidth*0.75;
                if (lfrt == LEFT) {
                    this.type = LEFT_UP;
                } else {
                    this.type = RIGHT_UP;
                }
            } else {
                this.y = vstrand.drawVstrand.y + baseWidth*1.75;
                if (lfrt == LEFT) {
                    this.type = LEFT_DOWN;
                } else {
                    this.type = RIGHT_DOWN;
                }
            }
            
            // draw appropriate lines
            this.graphics.clear();
            this.graphics.lineStyle(1, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 1);
            if (type == LEFT_UP) {
                this.graphics.moveTo(0,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,0);
            } else if (type == LEFT_DOWN) {
                this.graphics.moveTo(0,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,baseWidth);
            } else if (type == RIGHT_UP) {
                this.graphics.moveTo(baseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,0);
            } else if (type == RIGHT_DOWN) {
                this.graphics.moveTo(baseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,halfbaseWidth);
                this.graphics.lineTo(halfbaseWidth,baseWidth);
            }
            
            this.label.text = txt.toString();
            if (txt < 100) {
                this.format.size = 8;
            } else {
                this.format.size = 5;
            }
            this.label.setTextFormat(format);
            // center label
            var rect:Rectangle = this.label.getRect(this);
            var cp:Point = new Point((rect.right-rect.left)*0.5, (rect.bottom-rect.top)*0.5);
            this.label.x = 0;
            this.label.y = 0;
            if (vstrand.number % 2 == result) {
                DynamicRegistration.move(this.label, cp, halfbaseWidth, -0.4*baseWidth);
            } else {
                DynamicRegistration.move(this.label, cp, halfbaseWidth, 1.4*baseWidth);
            }
            
            this.visible = true; // restore visibility
        }
        
        private function mouseDownHandler(e:MouseEvent):void {
            if (e.shiftKey || e.altKey) {
                return; // ignore input when user is trying to join or move breakpoints
            } else {
                this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
            }
        }
        
        private function mouseUpHandler(e:MouseEvent):void {
            e.updateAfterEvent();
            this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
            
            if (strandType == SCAFFOLD) {
                this.drawPath.addScafCrossover(this, this.neighbor);
            } else if (strandType == STAPLE) {
                this.drawPath.addStapCrossover(this, this.neighbor);
                this.drawPath.updateStapleColor(this.vstrand, this.pos, this.tokenArray[this.pos].color);
                this.drawPath.updateStap(true);
            }
        }
    }
}
