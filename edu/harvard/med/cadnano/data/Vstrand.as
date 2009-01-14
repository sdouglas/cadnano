//
//  Vstrand
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
    // cadnano
    import edu.harvard.med.cadnano.Path;
    import edu.harvard.med.cadnano.data.Token;
    import edu.harvard.med.cadnano.data.SliceNode;
    import edu.harvard.med.cadnano.drawing.DrawVstrand;
    
    /*
    Vstrand is short for "virtual strand", and represents a single helix
    in the nanostructure.
    
    Vstrand stores scaffold and staple pointer pair arrays, along with
    a mutable strand number.
    */
    public class Vstrand {
        public var sliceNode:SliceNode;
        public var drawVstrand:DrawVstrand;
        public var number:int; // helix number
        public var row,col:int; // helix position
        public var scaf:Array; // scaffold Token pointer pairs
        public var stap:Array; // staple Token pointer pairs
        public var p0:Vstrand = null; // pointer to position 0 neighbor (\)
        public var p1:Vstrand = null; // pointer to position 1 neighbor (|)
        public var p2:Vstrand = null; // pointer to position 2 neighbor (/)
        
        public var loop:Array; // loop array
        public var skip:Array; // loop array
        public var scafLoop:Array = [];
        public var stapLoop:Array = [];
        
        function Vstrand(node:SliceNode,gridwidth:int) {
            this.sliceNode = node;
            this.number = sliceNode.number;
            this.row = node.row;
            this.col = node.col;
            this.scaf = new Array(gridwidth);
            this.stap = new Array(gridwidth);
            this.loop = new Array(gridwidth);
            this.skip = new Array(gridwidth);
            
            for (var i:int = 0; i < gridwidth; i++) {
                this.scaf[i] = new Token();
                this.scaf[i].color = DrawVstrand.COLORSCAF;
                this.stap[i] = new Token();
                this.stap[i].color = DrawVstrand.COLORSTAP;
                this.loop[i] = 0;
                this.skip[i] = 0;
            }
        }
        
        /* Called by Path.resetPathData() when loading a new design into memory. */
        public function clear():void {
            this.drawVstrand.clear();
            this.sliceNode = null;
            this.drawVstrand = null;
            this.scaf = null;
            this.stap = null;
            this.loop = null;
            this.skip = null;
            this.p0 = this.p1 = this.p2 = null;
        }
        
        
        /* Renumber according to transform dictionary. */
        public function reNumber(transform:Object):void {
            var i,p,n:int;
            var gridwidth:int = this.scaf.length;
            //trace("old num", this.number);
            this.number = int(transform[this.number.toString()]);
            //trace("new num", this.number);
            for (i = 0; i < gridwidth; i++) {
                p = this.scaf[i].prev_strand;
                if (p != -1) {this.scaf[i].prev_strand = int(transform[p]);}
                n = this.scaf[i].next_strand;
                if (n != -1) {this.scaf[i].next_strand = int(transform[n]);}
                p = this.stap[i].prev_strand;
                if (p != -1) {this.stap[i].prev_strand = int(transform[p]);}
                n = this.stap[i].next_strand;
                if (n != -1) {this.stap[i].next_strand = int(transform[n]);}
            }
            this.drawVstrand.reNumberCrossovers(transform);
            this.sliceNode.reNumber(transform);
        }
        
        /* Append 3' of scaf[pos] with extra loopSize bases of scaffold sequence. */
        public function addLoop(pos:int, loopSize:int):void {
            this.loop[pos] = loopSize;
            if (this.skip[pos] != 0) {
                this.skip[pos] = 0;
                this.drawVstrand.removeSkipHandle(pos);
            }
        }
        
        //FIX: What happens if a loop and skip are in the same position?
        //right now just resets other value... should also remove sprite.
        
        /* Remove loop from scaffold. */
        public function removeLoop(pos:int):void {
            this.loop[pos] = 0;
        }
        
        /* Get loop value at pos. */
        public function getLoop(pos:int):int {
            return this.loop[pos];
        }
        
        /* Do not populate scaf[pos] with scaffold sequence. */
        public function addSkip(pos:int):void {
            this.skip[pos] = -1;
            
            if (this.loop[pos] != 0) {
                this.loop[pos] = 0;
                this.drawVstrand.removeLoopHandle(pos);
            }
        }
        
        /* Skip a scaffold base. */
        public function removeSkip(pos:int):void {
            this.skip[pos] = 0;
        }
        
        /* Get Skip value at pos. */
        public function getSkip(pos:int):int {
            return this.skip[pos];
        }
        
        /* Return true if 5' or 3' is present in scaf */
        public function hasScaf(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.scaf.length-1) {
                return false;
            }
            
            if (this.scaf[pos].prev_pos != -1 ||
                this.scaf[pos].next_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if next 3' base is present after scaf[pos]. */
        public function scafHasPrevToken(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.scaf.length-1) {
                return false;
            }
            
            if (this.scaf[pos].prev_strand != -1 &&
                this.scaf[pos].prev_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if next 5' base is present before scaf[pos]. */
        public function scafHasNextToken(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.scaf.length-1) {
                return false;
            }
            
            if (this.scaf[pos].next_strand != -1 &&
                this.scaf[pos].next_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if next 3' base is present after stap[pos]. */
        public function stapHasPrevToken(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.stap.length-1) {
                return false;
            }
            
            if (this.stap[pos].prev_strand != -1 &&
                this.stap[pos].prev_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if next 5' base is present before stap[pos]. */
        public function stapHasNextToken(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.stap.length-1) {
                return false;
            }
            
            if (this.stap[pos].next_strand != -1 &&
                this.stap[pos].next_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if 5' end at scaf[pos]. */
        public function isScaf5PrimeEnd(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.scaf.length-1) {
                return false;
            }
            
            if (this.scaf[pos].next_pos != -1 && 
                this.scaf[pos].prev_pos == -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if 3' end at scaf[pos]. */
        public function isScaf3PrimeEnd(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.scaf.length-1) {
                return false;
            }
            
            if (this.scaf[pos].next_pos == -1 &&
                this.scaf[pos].prev_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if 5' or 3' is present in scaf */
        public function hasStap(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.stap.length-1) {
                return false;
            }
            
            if (this.stap[pos].prev_pos != -1 ||
                this.stap[pos].next_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if 5' end at stap[pos]. */
        public function isStap5PrimeEnd(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.stap.length-1) {
                trace("outside bounds", pos, this.stap.length-1);
                return false;
            }
            
            if (this.stap[pos].next_pos != -1 && 
                this.stap[pos].prev_pos == -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if 3' end at stap[pos]. */
        public function isStap3PrimeEnd(pos:int):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.stap.length-1) {
                return false;
            }
            
            if (this.stap[pos].next_pos == -1 &&
                this.stap[pos].prev_pos != -1) {
                return true;
            } else {
                return false;
            }
        }
        
        /* Return true if outgoing (3') crossover is present at scaf[pos]. 
           Also check for incoming (5') crossover by default. */
        public function hasScafXover(pos:int, check5prime=true, check3prime=true):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.scaf.length-1) {
                return false;
            }
            
            var delta:int = 1;
            if (this.number % 2 == 1) { // odd parity
                delta = -1;
            }
            
            if (check3prime) {
                if (this.scaf[pos].next_strand != -1) {
                    if (this.scaf[pos].next_strand != this.number) {
                            return true;
                    } else if (this.scaf[pos].next_pos != pos+delta) {
                        return true;
                    }
                } 
            }
            
            // In DrawPath.loadCrossoverHandles we only want to check 3' xovers
            if (check5prime) {
                if (this.scaf[pos].prev_strand != -1) {
                    if (this.scaf[pos].prev_strand != this.number) {
                        return true;
                    } else if (this.scaf[pos].prev_pos != pos-delta) {
                        return true;
                    }
                }
            }
            
            return false;
        }
        
        /* Return true if outgoing (3') crossover is present at stap[pos]. 
           Also check for incoming (5') crossover by default. */
        public function hasStapXover(pos:int, check5prime=true, check3prime=true):Boolean {
            // check if we're in bounds.
            if (pos < 0 || pos > this.stap.length-1) {
                return false;
            }
            
            var delta:int = 1;
            if (this.number % 2 == 0) { // odd parity
                delta = -1;
            }
            
            if (check3prime) {
                if (this.stap[pos].next_strand != -1) {
                    if (this.stap[pos].next_strand != this.number) {
                        return true;
                    } else if (this.stap[pos].next_pos != pos+delta) {
                        return true;
                    }
                } 
            }
            
            // In DrawPath.loadCrossoverHandles we only want to check 3' xovers
            if (check5prime) { // 
                if (this.stap[pos].prev_strand != -1) {
                    if (this.stap[pos].prev_strand != this.number) {
                        return true;
                    } else if (this.stap[pos].prev_pos != pos-delta) {
                        return true;
                    }
                }
            }
            return false;
        }
        
        /* Return true if scaffold is not continuous at pos. */
        public function scafBreakOrXover(pos):Boolean {
            if (pos < 0 || pos > this.scaf.length-1) {
                return false;
            }
            
            if ((this.scaf[pos].prev_strand == this.number && this.scaf[pos].next_strand != this.number) ||
                (this.scaf[pos].prev_strand != this.number && this.scaf[pos].next_strand == this.number)) {
                return true;
            } else if (this.number % 2 == 0 && this.scaf[pos].prev_strand == this.number && this.scaf[pos].prev_pos != pos-1) {
                return true;
            } else if (this.number % 2 == 0 && this.scaf[pos].next_strand == this.number && this.scaf[pos].next_pos != pos+1) {
                return true;
            } else if (this.number % 2 == 1 && this.scaf[pos].prev_strand == this.number && this.scaf[pos].prev_pos != pos+1) {
                return true;
            } else if (this.number % 2 == 1 && this.scaf[pos].next_strand == this.number && this.scaf[pos].next_pos != pos-1) {
                return true;
            }
            
            return false;
        }
        
        /* Return true if scaffold is not continuous at pos. */
        public function stapBreakOrXover(pos):Boolean {
            if (pos < 0 || pos > this.stap.length-1) {
                return false;
            }
            
            if ((this.stap[pos].prev_strand == this.number && this.stap[pos].next_strand != this.number) ||
                (this.stap[pos].prev_strand != this.number && this.stap[pos].next_strand == this.number)) {
                return true;
            } else if (this.number % 2 == 0 && this.stap[pos].prev_strand == this.number && this.stap[pos].prev_pos != pos-1) {
                return true;
            } else if (this.number % 2 == 0 && this.stap[pos].next_strand == this.number && this.stap[pos].next_pos != pos+1) {
                return true;
            } else if (this.number % 2 == 1 && this.stap[pos].prev_strand == this.number && this.stap[pos].prev_pos != pos+1) {
                return true;
            } else if (this.number % 2 == 1 && this.stap[pos].next_strand == this.number && this.stap[pos].next_pos != pos-1) {
                return true;
            }
            
            return false;
        }
        
        /*
        Prepend or append 21 new token pairs to this virtual strand.
        */
        public function extend(direction:String, segments:int=1) {
            var length:int = segments*21;
            
            var tempscaf:Array = new Array(length);
            var tempstap:Array = new Array(length);
            var temploop:Array = new Array(length);
            var tempskip:Array = new Array(length);
            
            for (var i:int = 0; i < length; i++) {
                tempscaf[i] = new Token();
                tempstap[i] = new Token();
                temploop[i] = 0;
                tempskip[i] = 0;
            }
            if (direction == Path.PREPEND) { // prepend
                // shift all values by length
                for (var j:int = 0; j < this.scaf.length; j++) {
                    if (this.scaf[j].prev_pos != -1) {
                        this.scaf[j].prev_pos += length;
                    }
                    if (this.scaf[j].next_pos != -1) {
                        this.scaf[j].next_pos += length;
                    }
                    if (this.stap[j].prev_pos != -1) {
                        this.stap[j].prev_pos += length;
                    }
                    if (this.stap[j].next_pos != -1) {
                        this.stap[j].next_pos += length;
                    }
                }
                this.scaf = tempscaf.concat(this.scaf);
                this.stap = tempstap.concat(this.stap);
                this.loop = temploop.concat(this.loop);
                this.skip = tempskip.concat(this.skip);
            } else if (direction == Path.APPEND) { // append
                this.scaf = this.scaf.concat(tempscaf);
                this.stap = this.stap.concat(tempstap);
                this.loop = this.loop.concat(temploop);
                this.skip = this.skip.concat(tempskip);
            }
        }
        
        /*
        Install default staple paths based on current scaffold paths.
        */
        public function autoStaple():void {
            var i,len:int;
            var scafBase:Boolean = false;  // is scaffold base present?
            
            // completely reset staple strands
            this.drawVstrand.clearStapBreakpoints();
            this.drawVstrand.clearStapCrossovers();
            for (i = 0; i < this.stap.length; i++) {
                this.stap[i].prev_strand = this.stap[i].prev_pos = -1;
                this.stap[i].next_strand = this.stap[i].next_pos = -1;
            }
            
            // find scaffold transitions to/from [-1,-1]
            for (i = 0; i < this.scaf.length; i++) {
                if (this.scafBreakOrXover(i)) {
                    scafBase = !scafBase;
                }
                
                // install staple token pointers based on scaffold transitions
                if (scafBase) {
                    if (this.number % 2 == 0) {
                        this.stap[i].prev_strand = this.number;
                        this.stap[i].prev_pos = i + 1;
                        this.stap[int(i+1)].next_strand = this.number;
                        this.stap[int(i+1)].next_pos = i;
                    } else {
                        this.stap[i].next_strand = this.number;
                        this.stap[i].next_pos = i+1;
                        this.stap[int(i+1)].prev_strand = this.number;
                        this.stap[int(i+1)].prev_pos = i;
                    }
                } // end if(scafBase)
            } // end for loop
            
            // seal nicks
            len = this.stap.length-1;
            if (this.number % 2 == 0) {
                for (i = 0; i < len; i++) {
                    if ((this.stap[i].next_strand != -1 && this.stap[i].next_pos != -1) &&
                        (this.stap[i].prev_strand == -1 && this.stap[i].prev_pos == -1) &&
                        (this.stap[int(i+1)].next_strand == -1 && this.stap[int(i+1)].next_pos == -1) &&
                        (this.stap[int(i+1)].prev_strand != -1 && this.stap[int(i+1)].prev_pos != -1)) {
                            this.stap[i].prev_strand = this.number;
                            this.stap[i].prev_pos = i+1;
                            this.stap[int(i+1)].next_strand = this.number;
                            this.stap[int(i+1)].next_pos = i;
                        }
                }
            } else {
                for (i = 0; i < len; i++) {
                    if ((this.stap[i].next_strand == -1 && this.stap[i].next_pos == -1) &&
                        (this.stap[i].prev_strand != -1 && this.stap[i].prev_pos != -1) &&
                        (this.stap[int(i+1)].next_strand != -1 && this.stap[int(i+1)].next_pos != -1) &&
                        (this.stap[int(i+1)].prev_strand == -1 && this.stap[int(i+1)].prev_pos == -1)) {
                        this.stap[int(i+1)].prev_strand = this.number;
                        this.stap[int(i+1)].prev_pos = i;
                        this.stap[i].next_strand = this.number;
                        this.stap[i].next_pos = i+1;
                    }
                }
            } // end seal nicks
        } // end autoStaple()
    } // end class Vstrand
} // end package edu.harvard.med.cadnano.data