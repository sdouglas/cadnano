//
//  VectorShapeFactory
//
//  Created by Shawn on 2008-07-21.
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
    import org.papervision3d.materials.special.VectorShapeMaterial;
    import org.papervision3d.objects.special.Graphics3D;
    import org.papervision3d.objects.special.VectorShape3D;
    
    public class VectorShapeFactory implements ObjectPoolFactory {
        private var material:VectorShapeMaterial;
        
        public function VectorShapeFactory(material:VectorShapeMaterial) {
            this.material = material;
        }
        
        public function create():* {
            var shape:VectorShape3D = new VectorShape3D(this.material);
            var g:Graphics3D = shape.graphics;
            g.lineStyle(0, 0xcc6600);
            g.beginFill(0xffcc99);
            g.drawCircle(0,0,Render3D.lineSize*0.5);
            g.endFill();
            return shape;
        }
    }
}