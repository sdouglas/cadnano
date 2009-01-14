//
//  Token.as
//
//  Created by Shawn on 2008-04-04.
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
    /*
    A Token stores the numeric indices of neighboring Tokens.
    */
    public class Token {
        public var prev_strand:int = -1;
        public var prev_pos:int = -1;
        public var next_strand:int = -1;
        public var next_pos:int = -1;
        public var sequence:String = "?";
        public var color:uint = 0x888888;
        public var highlight:Boolean = true;
        public var visited:Boolean = false;
        function Token() {}
        
        /* Set next_strand to strand and next_pos to pos. */
        public function setNext(strand:int, pos:int) {
            this.next_strand = strand;
            this.next_pos = pos;
            this.highlight = false;
        }
        
        /* Set next_strand and next_pos to -1. */
        public function clearNext() {
            this.next_strand = -1;
            this.next_pos = -1;
            this.highlight = false;
        }
        
        /* Set prev_strand to strand and prev_pos to pos. */
        public function setPrev(strand:int, pos:int) {
            this.prev_strand = strand;
            this.prev_pos = pos;
            this.highlight = false;
        }
        
        /* Set prev_strand and prev_pos to -1. */
        public function clearPrev() {
            this.prev_strand = -1;
            this.prev_pos = -1;
            this.highlight = false;
        }
        
        public function toString():String {
            return "[[" + this.prev_strand + ", " + this.prev_pos + "], [" + this.next_strand + ", " + this.next_pos + "]]";
        }
    }
}
