//
//  ToolButton
//
//  Created by Shawn on 2007-12-19.
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

package edu.harvard.med.cadnano.panel {
    // flash
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    // misc
    import com.yahoo.astra.utils.DynamicRegistration;
    
    // papervision
    import org.papervision3d.core.geom.Lines3D;
    
    /*
    ToolButton is a minimal extension of the Sprite class,
    allowing for simple textfield labeling and status ("enabled") tracking.
    Some default text formatting options are also maintained.
    */
    public class ToolButton extends Sprite {
        public var enabled:Boolean;
        public var tf:TextField;
        public var icon:Bitmap;
        public var layer:Sprite;
        private var format:TextFormat;
        public var lines:Lines3D;
        
        function ToolButton(label:String=null, color:uint=0xffffff) {
            this.name = label;
            enabled = false;
            if (label != null) {
                this.tf = new TextField();
                this.tf.text = label;
                this.tf.autoSize = "left";
                this.format = new TextFormat();
                this.format.align = "center";
                this.format.font = "Verdana";
                this.format.color = color;
                this.format.size = 10;
                this.tf.setTextFormat(format);
                this.tf.mouseEnabled = false;
                this.addChild(tf);
                
                var rect:Rectangle = this.tf.getRect(this);
                var point:Point = new Point((rect.right-rect.left)*0.5, 0);
                DynamicRegistration.move(this.tf, point, 16, 35);
            }
        }
    }
}