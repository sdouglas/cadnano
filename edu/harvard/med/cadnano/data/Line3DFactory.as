//
//  Line3DFactory
//
//  Created by Shawn on 2008-07-22.
//

/*
The MIT License

Copyright (c) 2007-2008 Shawn Douglas

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
    import de.polygonal.core.ObjectPoolFactory;
    import edu.harvard.med.cadnano.Render3D;
    import org.papervision3d.core.geom.Lines3D;
    import org.papervision3d.core.geom.renderables.Line3D;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.materials.special.LineMaterial;
    
    public class Line3DFactory implements ObjectPoolFactory {
        private var lines3D:Lines3D;
        private var material:LineMaterial;
        private var size:Number;
        
        public function Line3DFactory(lines3D:Lines3D, material:LineMaterial, size:Number) {
            this.lines3D = lines3D;
            this.material = material;
            this.size = size;
        }
        
        public function create():* {
            var line:Line3D = new Line3D(this.lines3D, this.material as LineMaterial, this.size, new Vertex3D(0,0,0), new Vertex3D(1,1,1));
            return line;
        }
    }
}
