//
//  SliceNode
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


package edu.harvard.med.cadnano.data {
    // flash
    import flash.display.Sprite;
    
    // cadnano
    import edu.harvard.med.cadnano.*;
    import edu.harvard.med.cadnano.drawing.*;
    import edu.harvard.med.cadnano.data.Vstrand;
    
    /*
    A SliceNode is an x-y plane cross-sectional representation of a helix.
    SliceNodes populate the slice array, and their data is what gets
    displayed by the DrawSlice routines.
    */
    public class SliceNode extends Sprite {
        // for debugging
        public var row:int;
        public var col:int;
        
        public var parity:int;
        public var p0neighbor:SliceNode;
        public var p1neighbor:SliceNode;
        public var p2neighbor:SliceNode;
        public var marked:Boolean;           // toggles when clicked
        public var number:int;               // helix number
        public var drawNode:DrawNode;
        
        public var vstrand:Vstrand;
        
        public function SliceNode(row:int, col:int) {
            this.row = row;
            this.col = col;
            this.parity = (row % 2) ^ (col % 2);
            this.p0neighbor = null;
            this.p1neighbor = null;
            this.p2neighbor = null;
            this.marked = false;
            this.number = -1;
            this.vstrand = null;
        }
        
        public function reNumber(transform):void {
            this.number = int(transform[this.number.toString()]);
            this.drawNode.reNumber();
        }
    }
}
