//
//  Slice
//
//  Created by Shawn on 2007-10-17.
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

package edu.harvard.med.cadnano {
    import edu.harvard.med.cadnano.data.SliceNode;
    
    /*
    A Slice instance is meant to store a 2D array of helix data, in the form
    of SliceNodes.  This facilitates populating spatial relationships
    between helices in the honeycomb lattice.  Slice and SliceNode classes
    might be combined at some point, since we no longer need to store
    multiple slices.
    */
    public class Slice {
        // store slice nodes in hash accessible by "row,col" keys
        public var sliceHash:Object;
        
        public function Slice(rows:int, cols:int) {
            var index:String;
            this.sliceHash = new Object();
            
            // create a SliceNode at each position in the grid
            for (var col:int = 0; col < cols; col++)
            {
                for (var row:int = 0; row < rows; row++)
                {
                    index = row + "," + col;
                    this.sliceHash[index] = new SliceNode(row, col);
                }
            }
            
            // Populate neighbor linkages
            var parity:int;
            var node:SliceNode;
            for (col = 0; col < cols; col++)
            {
                for (row = 0; row < rows; row++)
                {
                    index = row + "," + col;
                    node = this.sliceHash[index];
                    
                    if (node.parity) // odd parity
                    {
                        // if col-1 exists, set P0
                        if (col > 0) {
                            index = row + "," + (col-1);
                            node.p0neighbor = this.sliceHash[index];
                        }
                        // if row+1 exists, set P1
                        if (row < rows-1) {
                            index = (row+1) + "," + col;
                            node.p1neighbor = this.sliceHash[index];
                        }
                        // if col+1 exists, set P2
                        if (col < cols-1) {
                            index = row + "," + (col+1);
                            node.p2neighbor = this.sliceHash[index];
                        }
                    } else {         // even parity
                        // if col+1 exists, set P0
                        if (col < cols-1) {
                            index = row + "," + (col+1);
                            node.p0neighbor = this.sliceHash[index];
                        }
                        // if row-1 exists, set P1
                        if (row > 0) {
                            index = (row-1) + "," + col;
                            node.p1neighbor = this.sliceHash[index];
                        }
                        // if col-1 exists, set P2
                        if (col > 0) {
                            index = row + "," + (col-1);
                            node.p2neighbor = this.sliceHash[index];
                        }
                    }
                }
            }
        } // end Slice()
        
        /* Called by DataTools */
        public function getSliceNode(row:Number,col:Number):SliceNode {
            var index:String;
            index = row + "," + col;
            return this.sliceHash[index];
        }
        
        
        /* Called by DataTools */
        public function pairAllVstrands(path:Path):void {
            for each (var node in this.sliceHash) {
                if (node.number != -1) {
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
                }
            }
        }
    }
}
