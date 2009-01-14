//
//  LoopHandle
//
//  Created by Shawn on 2008-04-26.
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
    
    /*
    LoopHandle is a minimal extension of the Sprite class,
    allowing for simple handling of potential and real crossovers.
    
    */
    public class LoopHandle extends Sprite {
        private var baseWidth:int = DrawPath.baseWidth;
        private var halfbaseWidth:int = DrawPath.halfbaseWidth;
        
        private var vstrand:Vstrand;
        public var pos:int;
        private var loopSize:int;
        
        private var label:TextField;
        private var format:TextFormat;
        
        function LoopHandle(vstrand:Vstrand, pos:int, loopSize:int) {
            // bookkeeping
            this.vstrand = vstrand;
            this.pos = pos;
            this.x = pos*baseWidth;
            this.name = pos.toString();
            
            // data
            this.vstrand.addLoop(pos,loopSize);
            
            // appearance
            this.graphics.lineStyle(1, 0x0066cc);
            var dx:Number = 0.25*baseWidth;  // shift to right for even parity scaffold
            if (vstrand.number % 2 == 0) {
                this.graphics.moveTo(halfbaseWidth+dx,halfbaseWidth);
                this.graphics.curveTo(-halfbaseWidth+dx,-baseWidth,halfbaseWidth+dx,-baseWidth);
                this.graphics.curveTo(1.5*baseWidth+dx,-baseWidth,halfbaseWidth+dx,halfbaseWidth);
            } else {
                dx = -dx; // shift to left for odd parity scaffold
                this.y = baseWidth;
                this.graphics.moveTo(halfbaseWidth+dx,halfbaseWidth);
                this.graphics.curveTo(-halfbaseWidth+dx,2*baseWidth,halfbaseWidth+dx,2*baseWidth);
                this.graphics.curveTo(1.5*baseWidth+dx,2*baseWidth,halfbaseWidth+dx,halfbaseWidth);
            }
            this.label = new TextField();
            this.label.antiAliasType = AntiAliasType.ADVANCED;
            this.label.text = loopSize.toString();
            this.label.autoSize = "left";
            this.format = new TextFormat();
            this.format.font = "Verdana";
            if (loopSize < 100) {
                this.format.size = 8;
            } else {
                this.format.size = 5;
            }
            this.format.color = "0xcc6600";
            this.label.setTextFormat(format);
            this.label.mouseEnabled = false;
            this.addChild(label);
            var rect:Rectangle = this.label.getRect(this);
            var cp:Point = new Point((rect.right-rect.left)*0.5, (rect.bottom-rect.top)*0.5);
            if (vstrand.number % 2 == 0) {
                DynamicRegistration.move(this.label, cp, halfbaseWidth+dx, -0.4*baseWidth);
            } else {
                DynamicRegistration.move(this.label, cp, halfbaseWidth+dx, 1.4*baseWidth);
            }
            
            // interaction
            this.doubleClickEnabled = true;
            this.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler, false, 0, true);
        }
        
        private function doubleClickHandler(e:MouseEvent):void {
            e.updateAfterEvent();
            this.vstrand.removeLoop(this.pos);
            this.parent.removeChild(this);
            this.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
        }
    }
}
