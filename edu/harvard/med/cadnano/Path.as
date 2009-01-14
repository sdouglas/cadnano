//
//  Path
//
//  Created by Shawn on 2007-11-06.
//

/*
The Path class is used to create and maintain Vstrands.
DrawPath uses a Path instance to draw the user interface,
as well as to update the Vstrands with changes as the user
interacts with the interface.

The main "vsList" object is a doubly-linked list, in which each element 
is a Vstrand (virtual strand), corresponding to a DNA helix in the
nanostructure.
*/

package edu.harvard.med.cadnano {
    // misc
    import de.polygonal.ds.DLinkedList;
    import de.polygonal.ds.DListIterator;
    
    // cadnano
    import edu.harvard.med.cadnano.data.Vstrand;
    import edu.harvard.med.cadnano.data.SliceNode;
    import edu.harvard.med.cadnano.drawing.*;
    
    public class Path {
        public static var PREPEND:String = "prepend";
        public static var APPEND:String = "append";
        
        public var drawPath:DrawPath;
        public var vsList:DLinkedList;
        public var vsIter:DListIterator;
        public var vsHash:Object; // pointers to vstrands independent of vsList order
        
        public var loadedData:Boolean = false;
        
        function Path() {
            this.vsList = new DLinkedList();
            this.vsIter = this.vsList.getListIterator();
            this.vsHash = new Object();
        }
        
        public function resetPathData():void {
            this.drawPath.clearActiveVstrand();
            var vs:Vstrand = this.vsList.removeHead();
            while (vs != null) {
                vs.clear();
                vs = this.vsList.removeHead();
            }
        }
        
        /*
        Add newly clicked helix from SlicePanel to Path Panel.  Install
        some initial scaffold bases.
        */
        public function addHelix(node:SliceNode):void {
            var gridwidth:int;
            if (this.vsList.size == 0) { // use default size for first vstrand
                gridwidth = 42;
            } else { // use calculated size of existing vstrand
                gridwidth = this.vsList.head.data.scaf.length;
            }
            
            // Add virtual strand data structure
            var vs:Vstrand = new Vstrand(node,gridwidth);
            this.vsHash[vs.number] = vs;
            this.vsList.append(vs);
            node.vstrand = vs; // link node to its vstrand
            this.addBases(this.drawPath.currentSlice,vs); // populate new vstrand
            
            // Add virtual strand drawing methods
            var dv:DrawVstrand = new DrawVstrand(this.drawPath, vs, node, this.vsList.size-1);
            this.drawPath.addDrawVstrand(dv);
            
            this.drawPath.addHelixHandle(node,this.vsList.size-1);
            this.drawPath.addGridLines(this.vsList.size-1, vs.scaf.length);
            
            dv.addScafBreakpoints(); // add initial breakpoints
            dv.updateScafBreakBounds();
        }
        
        /*
        Update pointer pairs to create a few bases
        */
        public function addBases(i:int, vs:Vstrand) {
            // get away from edge
            if (i == 0) {
                this.drawPath.currentSlice = ++i;
                this.drawPath.redrawSliceBar();
            } else if (this.drawPath.currentSlice == vs.scaf.length-1) {
                this.drawPath.currentSlice = --i;
                this.drawPath.redrawSliceBar();
            }
            
            // add some scaffold bases
            vs.scaf[i].prev_strand = vs.number;
            vs.scaf[i].next_strand = vs.number;
            
            if (vs.number % 2 == 0) { // even parity
                // update upstream next pointer to point to this
                vs.scaf[int(i-1)].next_strand = vs.number;
                vs.scaf[int(i-1)].next_pos = i;
                
                // update this prev to point upstream
                vs.scaf[i].prev_pos = i - 1;
                // update this next to point downstream
                vs.scaf[i].next_pos = i + 1;
                
                // update downstream prev to point to this
                vs.scaf[i+1].prev_strand = vs.number;
                vs.scaf[i+1].prev_pos = i;
            } else {
                // update upstream prev to point to this
                vs.scaf[int(i-1)].prev_strand = vs.number;
                vs.scaf[int(i-1)].prev_pos = i;
                
                // update this prev to point downstram
                vs.scaf[i].prev_pos = i + 1;
                // update this next to point upstream
                vs.scaf[i].next_pos = i - 1;
                
                // update downstream next to point to this
                vs.scaf[i+1].next_strand = vs.number;
                vs.scaf[i+1].next_pos = i;
            }
        }
        
        /*
        Update pointer pairs to create a few staple bases
        */
        public function addStapleBases(i:int, vs:Vstrand) {
            // get away from edge
            if (i == 0) {
                this.drawPath.currentSlice = ++i;
                this.drawPath.redrawSliceBar();
            } else if (this.drawPath.currentSlice == vs.stap.length-1) {
                this.drawPath.currentSlice = --i;
                this.drawPath.redrawSliceBar();
            }
            
            // add some stapfold bases
            vs.stap[i].prev_strand = vs.number;
            vs.stap[i].next_strand = vs.number;
            
            if (vs.number % 2 == 1) { // odd parity
                // update upstream next pointer to point to this
                vs.stap[int(i-1)].next_strand = vs.number;
                vs.stap[int(i-1)].next_pos = i;
                
                // update this prev to point upstream
                vs.stap[i].prev_pos = i - 1;
                // update this next to point downstream
                vs.stap[i].next_pos = i + 1;
                
                // update downstream prev to point to this
                vs.stap[i+1].prev_strand = vs.number;
                vs.stap[i+1].prev_pos = i;
            } else {
                // update upstream prev to point to this
                vs.stap[int(i-1)].prev_strand = vs.number;
                vs.stap[int(i-1)].prev_pos = i;
                
                // update this prev to point downstram
                vs.stap[i].prev_pos = i + 1;
                // update this next to point upstream
                vs.stap[i].next_pos = i - 1;
                
                // update downstream next to point to this
                vs.stap[i+1].next_strand = vs.number;
                vs.stap[i+1].next_pos = i;
            }
        }
        
        public function extendVstrands(type:String, segments:int=1):void {
            var iter:DListIterator = this.vsList.getListIterator();
            for (iter.start(); iter.valid(); iter.forth()) {
                iter.data.extend(type, segments); // extend every vstrand
                if (type == PREPEND) {
                    iter.data.drawVstrand.shiftHandles(segments); // shift all handles (xo, loop, skip)
                }
            }
            if (type == PREPEND) {
                // snap to end by default
                this.drawPath.currentSlice = 0;
                // keep canvas centered
                this.drawPath.x = this.drawPath.x - segments*21*DrawPath.baseWidth;
            } else if (type == APPEND) {
                this.drawPath.currentSlice += segments*21;
            }
            this.drawPath.update();
        }
        
        /* Renumber helices in ascending order according to position in vsList. */
        public function renumberHelices():void {
            var vs:Vstrand;
            var transform:Object = new Object();
            var helixNum,i:int;
            var iter:DListIterator = this.vsList.getListIterator();
            var even:int = -2;
            var odd:int = -1;
            
            // "sort" and decorate
            for (iter.start(); iter.valid(); iter.forth()) {
                vs = iter.data;
                helixNum = vs.number;
                if (helixNum % 2 == 0) {
                    even += 2;
                    transform[helixNum] = 1000 + even;
                } else {
                    odd += 2;
                    transform[helixNum] = 1000 + odd;
                }
            }
            for (iter.start(); iter.valid(); iter.forth()) {
                vs = iter.data;
                vs.reNumber(transform);
            }
            
            // undecorate
            for (iter.start(); iter.valid(); iter.forth()) {
                vs = iter.data;
                helixNum = vs.number;
                transform[helixNum] = helixNum - 1000;
            }
            
            for (var key in this.vsHash) {  // reset vsHash
                delete this.vsHash[key];
            }
            for (iter.start(); iter.valid(); iter.forth()) {
                vs = iter.data;
                vs.reNumber(transform);
                this.vsHash[vs.number] = vs;
            }
            this.drawPath.reNumberHelixLabels();
        }
        
        /* 
        When SliceNodes are updated by clicking in the slice panel
        it is necessary to link the corresponding Vstrands that are
        created so stage coordinates can be easily determined when
        crossovers are drawn.
        */
        public function pairHelices(vs1:Vstrand, vs2:Vstrand, p:int):void {
            if (p == 0) {
                vs1.p0 = vs2;
                vs2.p0 = vs1;
            }
            if (p == 1) {
                vs1.p1 = vs2;
                vs2.p1 = vs1;
            }
            if (p == 2) {
                vs1.p2 = vs2;
                vs2.p2 = vs1;
            }
        }
        
        public function importVstrands(vsl:DLinkedList):void {
            var vs:Vstrand;
            var rank:int = 0;
            
            this.vsList = vsl;
            this.vsIter = this.vsList.getListIterator();
            for (var key in this.vsHash) {  // reset vsHash
                delete this.vsHash[key];
            }
            
            for (vsIter.start(); vsIter.valid(); vsIter.forth()) {
                vs = vsIter.node.data;
                this.vsHash[vs.number] = vs;
                var dv:DrawVstrand = new DrawVstrand(this.drawPath, vs, vs.sliceNode, rank, false);
                this.drawPath.addDrawVstrand(dv);
                this.drawPath.addHelixHandle(vs.sliceNode, rank);
                rank += 1;
            }
            
            this.loadedData = true;
        }
    }
}
