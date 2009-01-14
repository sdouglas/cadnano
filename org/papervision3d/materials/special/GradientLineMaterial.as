package org.papervision3d.materials.special {
    
    /**
     * @Author Mark Barcinski
     */
    import flash.geom.Matrix;
    import org.papervision3d.core.geom.renderables.Vertex3DInstance;
    
    import flash.display.InterpolationMethod;
    import flash.display.SpreadMethod;
    import flash.display.Graphics;
    
    import org.papervision3d.core.geom.renderables.Line3D;
    import org.papervision3d.core.render.data.RenderSessionData;
    import org.papervision3d.core.render.draw.ILineDrawer;
    import org.papervision3d.core.geom.renderables.Vertex3D;
    
    public class GradientLineMaterial extends LineMaterial implements ILineDrawer
    {
        private var colors : Array = [0x800000, 0xFF0000 , 0x800000 ];
        private var alphas : Array = [100, 100, 100];
        private var ratios : Array = [0, 125 , 255];
        
        private var spreadMethod : String;
        private var interpolationMethod:String;
        private var matrix : Matrix;
        
        static private var halfPI :Number = Math.PI/2;
        
        public function GradientLineMaterial(colors:Array = null , alphas:Array = null , ratios:Array = null , 
                                            spreadMethod:String = SpreadMethod.REPEAT , 
                                            interpolationMethod:String = InterpolationMethod.LINEAR_RGB )
        {
            super();
            
            if(colors != null) this.colors = colors;
            if(alphas != null) this.alphas = alphas;
            if(ratios != null) this.ratios = ratios;
            this.spreadMethod = spreadMethod;
            this.interpolationMethod = interpolationMethod;
            matrix = new Matrix();
        }
        
        public override function drawLine(line:Line3D, graphics:Graphics, renderSessionData:RenderSessionData):void
        {   
            //if(line.hasRenderd)return;
            var focus    :Number = renderSessionData.camera.focus;
            var fz       :Number = focus * renderSessionData.camera.zoom;
            
            //trace(persp);
            var v0Scale  :Number = (fz / (focus + line.v0.vertex3DInstance.z)) * 0.5 * line.size;
            var v1Scale  :Number = (fz / (focus + line.v1.vertex3DInstance.z)) * 0.5 * line.size;
            
            var Stroke:Number = Math.max(v1Scale, v0Scale);
            
            var x0:Number = line.v0.vertex3DInstance.x;
            var y0:Number = line.v0.vertex3DInstance.y;
            
            var x1:Number = line.v0.vertex3DInstance.x;
            var y1:Number = line.v0.vertex3DInstance.y;
            
            var x2:Number = line.v1.vertex3DInstance.x;
            var y2:Number = line.v1.vertex3DInstance.y;
            
            var x3:Number = line.v1.vertex3DInstance.x;
            var y3:Number = line.v1.vertex3DInstance.y;
            
            var rot:Number = Math.atan2( x2 - x1 , y2 - y1 );
            
            matrix.createGradientBox(Stroke*2, Stroke*2, 0 , Math.sin(rot-1.55) * Stroke * 0.4, Stroke * 0.2);
            matrix.rotate(rot * -1);
            matrix.translate(x1, y1);
            
            var tempSin:Number = Math.sin(rot - halfPI);
            var tempCos:Number = Math.cos(rot - halfPI);
            
            x0 -= tempSin * v0Scale;
            y0 -= tempCos * v0Scale;
            
            x1 += tempSin * v0Scale;
            y1 += tempCos * v0Scale;
            
            x2 += tempSin * v1Scale;
            y2 += tempCos * v1Scale;
            
            x3 -= tempSin * v1Scale;
            y3 -= tempCos * v1Scale;
            
            graphics.lineStyle();
            graphics.beginGradientFill("linear", colors, alphas, ratios, matrix ,  spreadMethod, interpolationMethod);
            graphics.moveTo( x0, y0 );  
            graphics.curveTo(line.v0.vertex3DInstance.x - (Math.sin(rot) * v0Scale), line.v0.vertex3DInstance.y - (Math.cos(rot) * v0Scale), x1, y1);
            graphics.lineTo( x2, y2 );
            graphics.curveTo(line.v1.vertex3DInstance.x + (Math.sin(rot) * v1Scale), line.v1.vertex3DInstance.y + (Math.cos(rot) * v1Scale), x3, y3);
            graphics.lineTo( x0, y0 );
            graphics.endFill();
        }
    }
}