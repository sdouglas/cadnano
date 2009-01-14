//
//  SkipHandle
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
    SkipHandle is a minimal extension of the Sprite class,
    allowing for simple handling of potential and real crossovers.
    
    */
    public class SkipHandle extends Sprite {
        private var baseWidth:int = DrawPath.baseWidth;
        private var halfbaseWidth:int = DrawPath.halfbaseWidth;
        
        private var vstrand:Vstrand;
        public var pos:int;
        
        function SkipHandle(vstrand:Vstrand, pos:int) {
            // bookkeeping
            this.vstrand = vstrand;
            this.pos = pos;
            this.x = pos*baseWidth;
            this.name = pos.toString();
            
            // data
            this.vstrand.addSkip(pos);
            
            // appearance
            this.graphics.beginFill(0xffffff, 0.5);
            this.graphics.drawRect(0,0,baseWidth,baseWidth);
            this.graphics.endFill();
            this.graphics.lineStyle(2, 0xcc0000);
            this.graphics.moveTo(0.1*baseWidth,0.1*baseWidth);
            this.graphics.lineTo(0.9*baseWidth,0.9*baseWidth);
            this.graphics.moveTo(0.9*baseWidth,0.1*baseWidth);
            this.graphics.lineTo(0.1*baseWidth,0.9*baseWidth);
            if (vstrand.number % 2 == 1) {
                this.y = baseWidth;
            }
            
            // interaction
            this.doubleClickEnabled = true;
            this.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler, false, 0, true);
        }
        
        private function doubleClickHandler(e:MouseEvent):void {
            e.updateAfterEvent();
            this.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
            this.vstrand.removeSkip(this.pos);
            this.parent.removeChild(this);
            this.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
        }
    }
}
