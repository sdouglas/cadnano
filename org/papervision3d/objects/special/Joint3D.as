package org.papervision3d.objects.special
{
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.objects.DisplayObject3D;

	/**
	 * class Joint3D
	 * <p></p>
	 * 
	 * @author Tim Knip
	 */ 
	public class Joint3D extends DisplayObject3D
	{
		/**
		 * Vertex weights. Used by skinning.
		 */ 
		public var vertexWeights:Array;
		
		/**
		 * Inverse bind matrix. Used by skinning.
		 */ 
		public var inverseBindMatrix:Matrix3D;
		
		/**
		 * Constructor.
		 * 
		 * @param	name
		 */ 
		public function Joint3D(name:String=null)
		{
			super(name);
			this.vertexWeights = new Array();
		}	
	}
}