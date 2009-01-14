package org.papervision3d.objects.special
{
	import org.papervision3d.core.geom.TriangleMesh3D;
	import org.papervision3d.core.geom.renderables.Vertex3D;
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.core.render.data.RenderSessionData;
	import org.papervision3d.objects.DisplayObject3D;

	/**
	 * class Skin3D
	 * <p></p>
	 * 
	 * @author Tim Knip
	 */ 
	public class Skin3D extends TriangleMesh3D
	{		
		/** Array of joints influencing this mesh. @see org.papervision3d.objects.special.Joint3D */
		public var joints:Array;

		/** Array of skeletons, a 'skeleton' is the root of a joint hierarchy. @see org.papervision3d.objects.special.Joint3D */
		public var skeletons:Array;
		
		/** The skin's bindshape matrix. */
		public var bindShapeMatrix:Matrix3D;
		
		/** Negate Z-axis in the skinning algo? (DAE needs true)*/
		public var negateZ:Boolean;
		
		/**
		 * Constructor.
		 * 
		 * @param	material
		 * @param	vertices
		 * @param	faces
		 * @param	name
		 * @param	negateZ Whether to negate Z in the skinning algorithm.
		 */ 
		public function Skin3D(material:MaterialObject3D, vertices:Array, faces:Array, name:String=null, negateZ:Boolean=false)
		{
			super(material, vertices, faces, name);
			
			this.negateZ = negateZ;
			this.joints = new Array();
			this.skeletons = new Array();
		}
		
		/**
		 * Project.
		 * 
		 * @param	parent
		 * @param	renderSessionData
		 */ 
		public override function project(parent:DisplayObject3D, renderSessionData:RenderSessionData):Number
		{
			if(this.bindShapeMatrix && this.skeletons.length && this.joints.length)
			{
				if(!_cached)
					cacheVertices();
					
				var i:int;	
				var vertices:Array = this.geometry.vertices;
				var joints:Array = this.joints;
				var skeletons:Array = this.skeletons;
				
				// reset mesh's vertices to 0
				for(i = 0; i < vertices.length; i++)
					vertices[i].x = vertices[i].y = vertices[i].z = 0;
					
				// project skeleton(s)
				for each(var joint:Joint3D in skeletons)
					joint.project(renderSessionData.camera, renderSessionData);
				
				// skin the mesh!
				for(i = 0; i < joints.length; i++)
					skinMesh(joints[i], _cached, vertices);
			}
			
			return super.project(parent, renderSessionData);
		}
		
		/**
		 * Cache original vertices.
		 */
		private function cacheVertices():void
		{
			var vertices:Array = this.geometry.vertices;

			_cached = new Array(vertices.length);
			
			for(var i:int = 0; i < vertices.length; i++)
			{
				_cached[i] = new Number3D(vertices[i].x, vertices[i].y, vertices[i].z);
				
				// move vertices to the bind pose.
				Matrix3D.multiplyVector(this.bindShapeMatrix, _cached[i]);
			}
			
		}
		
		/**
		 * Skins a mesh.
		 * 
		 * @param	joint
		 * @param	meshVerts
		 * @param	skinnedVerts
		 */
		private function skinMesh(joint:Joint3D, meshVerts:Array, skinnedVerts:Array):void
		{
			var i:int;
			var pos:Number3D = new Number3D();
			var original:Number3D;
			var skinned:Vertex3D;
			var vertexWeights:Array = joint.vertexWeights;

			var matrix:Matrix3D = Matrix3D.multiply(joint.world, joint.inverseBindMatrix);
			
			for( i = 0; i < vertexWeights.length; i++ )
			{
				var weight:Number = vertexWeights[i].weight;
				var vertexIndex:int = vertexWeights[i].vertexIndex;

				if( weight <= 0.0001 || weight >= 1.0001) continue;
								
				original = meshVerts[ vertexIndex ];	
				skinned = skinnedVerts[ vertexIndex ];
				
				pos.x = original.x;
				pos.y = original.y;
				pos.z = original.z;
							
				// joint transform
				Matrix3D.multiplyVector(matrix, pos);	

				//update the vertex
				skinned.x += (pos.x * weight);
				if(negateZ)
				{
					skinned.y += (pos.y * weight);
					skinned.z -= (pos.z * weight);
				}
				else
				{
					skinned.y += (pos.y * weight);
					skinned.z += (pos.z * weight);
				}
			}
		}
		
		private var _cached:Array;
	}
}