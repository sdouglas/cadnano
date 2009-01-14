/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.charts.series
{
	import com.yahoo.astra.animation.Animation;
	import com.yahoo.astra.animation.AnimationEvent;
	import com.yahoo.astra.fl.charts.PieChart;
	import com.yahoo.astra.fl.charts.skins.RectangleSkin;
	
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
		
	//--------------------------------------
	//  Styles
	//--------------------------------------

	/**
     * The colors of the markers in this series.
     *
     * @default [0x729fcf, 0xfcaf3e, 0x73d216, 0xfce94f, 0xad7fa8, 0x3465a4]
     */
    [Style(name="fillColors", type="Array")]
    
	/**
	 * Renders data points as a series of pie-like wedges.
	 * 
	 * @author Josh Tynjala
	 */
	public class PieSeries extends Series
	{
		
	//--------------------------------------
	//  Class Variables
	//--------------------------------------
		
		/**
		 * @private
		 */
		private static var defaultStyles:Object = 
		{	
			fillColors:
			[
				0x00b8bf, 0x8dd5e7, 0xc0fff6, 0xffa928, 0xedff9f, 0xd00050,
				0xc6c6c6, 0xc3eafb, 0xfcffad, 0xcfff83, 0x444444, 0x4d95dd,
				0xb8ebff, 0x60558f, 0x737d7e, 0xa64d9a, 0x8e9a9b, 0x803e77
			],
			markerSkins: [RectangleSkin]
		};
		
		/**
		 * @private
		 */
		private static const RENDERER_STYLES:Object = 
		{
			fillColor: "fillColors",
			skin: "markerSkins"
		};
		
	//--------------------------------------
	//  Class Methods
	//--------------------------------------
	
		/**
		 * @copy fl.core.UIComponent#getStyleDefinition()
		 */
		public static function getStyleDefinition():Object
		{
			return mergeStyles(defaultStyles, Series.getStyleDefinition());
		}
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 * Constructor.
		 */
		public function PieSeries(data:Object = null)
		{
			super(data);
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
		
		/**
		 * @private
		 * The Animation instance that controls animation in this series.
		 */
		private var _animation:Animation;
		
		/**
		 * @private
		 */
		private var _previousData:Array = [];
		
		/**
		 * @private
		 * Storage for the dataField property.
		 */
		private var _dataField:String;
		
		/**
		 * The field used to access data for this series.
		 */
		public function get dataField():String
		{
			return this._dataField;
		}
		
		/**
		 * @private
		 */
		public function set dataField(value:String):void
		{
			if(this._dataField != value)
			{
				this._dataField = value;
				this.dispatchEvent(new Event("dataChange"));
				this.invalidate(InvalidationType.DATA);
			}
		}
		
		/**
		 * @private
		 * Storage for the categoryField property.
		 */
		private var _categoryField:String;
		
		/**
		 * @copy com.yahoo.astra.fl.charts.series.ICategorySeries#categoryField
		 */
		public function get categoryField():String
		{
			return this._categoryField;
		}
		
		/**
		 * @private
		 */
		public function set categoryField(value:String):void
		{
			if(this._categoryField != value)
			{
				this._categoryField = value;
				this.dispatchEvent(new Event("dataChange"));
				this.invalidate(InvalidationType.DATA);
			}
		}
		
		/**
		 * @private
		 * Storage for the categoryNames property.
		 */
		private var _categoryNames:Array;
		
		/**
		 * @copy com.yahoo.astra.fl.charts.series.ICategorySeries#categoryNames
		 */
		public function get categoryNames():Array
		{
			return this._categoryNames;
		}
		
		/**
		 * @private
		 */
		public function set categoryNames(value:Array):void
		{
			this._categoryNames = value;
		}
		
		protected var markerMasks:Array = [];
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
	
		/**
		 * @copy com.yahoo.astra.fl.charts.ISeries#clone()
		 */
		override public function clone():ISeries
		{
			var series:PieSeries = new PieSeries();
			if(this.dataProvider is Array)
			{
				//copy the array rather than pass it by reference
				series.dataProvider = (this.dataProvider as Array).concat();
			}
			else if(this.dataProvider is XMLList)
			{
				series.dataProvider = (this.dataProvider as XMLList).copy();
			}
			series.displayName = this.displayName;
			
			return series;
		}
		
		public function itemToData(item:Object):Number
		{
			var primaryDataField:String = PieChart(this.chart).seriesToDataField(this);
			if(primaryDataField)
			{
				return Number(item[primaryDataField]);
			}
			return Number(item);
		}
		
		public function itemToCategory(item:Object, index:int):String
		{
			var primaryCategoryField:String = PieChart(this.chart).seriesToCategoryField(this);
			if(primaryCategoryField)
			{
				return item[primaryCategoryField];
			}
			
			if(this._categoryNames && index >= 0 && index < this._categoryNames.length)
			{
				return this._categoryNames[index];
			}
			return index.toString();
		}
		
		public function itemToPercentage(item:Object):Number
		{
			var totalValue:Number = 0;
			var itemCount:int = this.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var currentItem:Object = this.dataProvider[i];
				var value:Number = this.itemToData(currentItem);
				
				if(!isNaN(value))
				{
					totalValue += value;
				}
			}
			
			if(totalValue == 0) return 0;
			return (this.itemToData(item) / totalValue);
		}
		
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			var stylesInvalid:Boolean = this.isInvalid(InvalidationType.STYLES);
			var sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			var dataInvalid:Boolean = this.isInvalid(InvalidationType.DATA);
			super.draw();
			
			var itemCount:int = this.length;
			if(!this._previousData || this._previousData.length != this.length)
			{
				this._previousData = [];
				for(var i:int = 0; i < itemCount; i++)
				{
					this._previousData.push(0);
				}
			}
			
			var markerCount:int = this.markers.length;
			for(i = 0; i < markerCount; i++)
			{
				var marker:UIComponent = UIComponent(this.markers[i]);
				
				if(stylesInvalid)
				{
					this.copyStylesToRenderer(ISeriesItemRenderer(marker), RENDERER_STYLES);
				}
				
				if(sizeInvalid)
				{
					marker.width = this.width;
					marker.height = this.height;
				}
				//not really required, but we should validate anyway.
				this.validateMarker(ISeriesItemRenderer(marker));
			}
			
			//handle animating all the markers in one fell swoop.
			if(this._animation)
			{
				if(this._animation.active)
				{
					this._animation.pause();
				}
				this._animation.removeEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
				this._animation.removeEventListener(AnimationEvent.PAUSE, tweenPauseHandler);
				this._animation.removeEventListener(AnimationEvent.COMPLETE, tweenCompleteHandler);
				this._animation = null;
			}
			
			var data:Array = this.dataProviderToArrayOfNumbers();
			
			//don't animate on livepreview!
			if(this.isLivePreview || !this.getStyleValue("animationEnabled"))
			{
				this.drawMarkers(data);
			}
			else
			{
				var animationDuration:int = this.getStyleValue("animationDuration") as int;
				var animationEasingFunction:Function = this.getStyleValue("animationEasingFunction") as Function;
				
				this._animation = new Animation(animationDuration, this._previousData, data);
				this._animation.addEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
				this._animation.addEventListener(AnimationEvent.PAUSE, tweenPauseHandler);
				this._animation.addEventListener(AnimationEvent.COMPLETE, tweenCompleteHandler);
				this._animation.easingFunction = animationEasingFunction;
				this.drawMarkers(this._previousData);
			}
		}
		
		/**
		 * @private
		 * All markers are removed from the display list.
		 */
		override protected function removeAllMarkers():void
		{
			super.removeAllMarkers();
			var markerCount:int = this.markerMasks.length;
			for(var i:int = 0; i < markerCount; i++)
			{
				var mask:Shape = this.markerMasks.pop() as Shape;
				this.removeChild(mask);
			}
		}
		
		/**
		 * @private
		 * Add or remove markers as needed. current markers will be reused.
		 */
		override protected function refreshMarkers():void
		{
			super.refreshMarkers();
			
			var itemCount:int = this.length;
			var difference:int = itemCount - this.markerMasks.length;
			if(difference > 0)
			{
				for(var i:int = 0; i < difference; i++)
				{
					var mask:Shape = new Shape();
					this.addChild(mask);
					this.markerMasks.push(mask);
					
					var marker:Sprite = this.markers[i] as Sprite;
					marker.mask = mask;
				}
			}
			else if(difference < 0)
			{
				difference = Math.abs(difference);
				for(i = 0; i < difference; i++)
				{
					mask = this.markerMasks.pop() as Shape;
					this.removeChild(mask);
				}
			}
		}
		
	//--------------------------------------
	//  Private Methods
	//--------------------------------------
	
		/**
		 * @private
		 */
		private function dataProviderToArrayOfNumbers():Array
		{
			var output:Array = [];
			
			var itemCount:int = this.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this.dataProvider[i];
				var value:Number = 0;
				if(item != null)
				{
					value = this.itemToData(item);
				}
				output.push(value);
			}
			return output;
		}
	
		/**
		 * @private
		 */
		private function tweenUpdateHandler(event:AnimationEvent):void
		{
			this.drawMarkers(event.parameters as Array);
		}
		
		/**
		 * @private
		 */
		private function tweenCompleteHandler(event:AnimationEvent):void
		{
			this.tweenUpdateHandler(event);
			this.tweenPauseHandler(event);
		}
		
		/**
		 * @private
		 */
		private function tweenPauseHandler(event:AnimationEvent):void
		{
			this._previousData = (event.parameters as Array).concat();
		}
	
		/**
		 * @private
		 */
		private function drawMarkers(data:Array):void
		{
			var values:Array = [];
			var totalValue:Number = 0;
			var itemCount:int = data.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var value:Number = Number(data[i]);
				
				values.push(value);
				if(!isNaN(value))
				{
					totalValue += value;
				}
			}
			
			var totalAngle:Number = 0;
			var halfWidth:Number = this.width / 2;
			var halfHeight:Number = this.height / 2;
			var radius:Number = Math.min(halfWidth, halfHeight);
			var fillColors:Array = this.getStyleValue("fillColors") as Array;
			
			for(i = 0; i < itemCount; i++)
			{
				value = Number(data[i]);
				var angle:Number;
				if(totalValue == 0) angle = 360 / data.length;
				else angle = 360 * (value / totalValue);
				
				var mask:Shape = this.markerMasks[i] as Shape;
				mask.graphics.clear();
				mask.graphics.beginFill(0xff0000);
				this.drawWedge(mask.graphics, halfWidth, halfHeight, totalAngle, angle, radius);
				mask.graphics.endFill();
				totalAngle += angle;
				
				var marker:UIComponent = UIComponent(this.markers[i]);
				marker.drawNow();
			}
		}
		
		/**
		 * @private
		 * Draws a wedge.
		 * 
		 * @param x				x component of the wedge's center point
		 * @param y				y component of the wedge's center point
		 * @param startAngle	starting angle in degrees
		 * @param arc			sweep of the wedge. Negative values draw clockwise.
		 * @param radius		radius of wedge. If [optional] yRadius is defined, then radius is the x radius.
		 * @param yRadius		[optional] y radius for wedge.
		 */
		private function drawWedge(target:Graphics, x:Number, y:Number, startAngle:Number, arc:Number, radius:Number, yRadius:Number = NaN):void
		{
			// move to x,y position
			target.moveTo(x, y);
			
			// if yRadius is undefined, yRadius = radius
			if(isNaN(yRadius))
			{
				yRadius = radius;
			}
			
			// limit sweep to reasonable numbers
			if(Math.abs(arc) > 360)
			{
				arc = 360;
			}
			
			// Flash uses 8 segments per circle, to match that, we draw in a maximum
			// of 45 degree segments. First we calculate how many segments are needed
			// for our arc.
			var segs:int = Math.ceil(Math.abs(arc) / 45);
			
			// Now calculate the sweep of each segment.
			var segAngle:Number = arc / segs;
			
			// The math requires radians rather than degrees. To convert from degrees
			// use the formula (degrees/180)*Math.PI to get radians.
			var theta:Number = -(segAngle / 180) * Math.PI;
			
			// convert angle startAngle to radians
			var angle:Number = -(startAngle / 180) * Math.PI;
			
			// draw the curve in segments no larger than 45 degrees.
			if(segs > 0)
			{
				// draw a line from the center to the start of the curve
				var ax:Number = x + Math.cos(startAngle / 180 * Math.PI) * radius;
				var ay:Number = y + Math.sin(-startAngle / 180 * Math.PI) * yRadius;
				target.lineTo(ax, ay);
				
				// Loop for drawing curve segments
				for(var i:int = 0; i < segs; i++)
				{
					angle += theta;
					var angleMid:Number = angle - (theta / 2);
					var bx:Number = x + Math.cos(angle) * radius;
					var by:Number = y + Math.sin(angle) * yRadius;
					var cx:Number = x + Math.cos(angleMid) * (radius / Math.cos(theta / 2));
					var cy:Number = y + Math.sin(angleMid) * (yRadius / Math.cos(theta / 2));
					target.curveTo(cx, cy, bx, by);
				}
				// close the wedge by drawing a line to the center
				target.lineTo(x, y);
			}
		}
		
		protected function copyStylesToRenderer(child:ISeriesItemRenderer, styleMap:Object):void
		{
			var index:int = this.markers.indexOf(child);
			var childComponent:UIComponent = child as UIComponent;
			for(var n:String in styleMap)
			{
				var styleValues:Array = this.getStyleValue(styleMap[n]) as Array;
				//if it doesn't exist, ignore it and go with the defaults for this series
				if(!styleValues) continue;
				childComponent.setStyle(n, styleValues[index % styleValues.length])
			}
		}
		
	}
}