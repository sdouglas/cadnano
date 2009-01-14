/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.charts.series
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import fl.core.UIComponent;
	import com.yahoo.astra.fl.charts.*;
	import com.yahoo.astra.fl.charts.skins.CircleSkin;
	import com.yahoo.astra.fl.charts.skins.IProgrammaticSkin;
	import com.yahoo.astra.animation.Animation;
	import com.yahoo.astra.animation.AnimationEvent;
	
	/**
     * The weight, in pixels, of the line drawn between points in this series.
     *
     * @default 3
     */
    [Style(name="lineWeight", type="Number")]
    
	/**
	 * Renders data points as a series of connected line segments.
	 * 
	 * @author Josh Tynjala
	 */
	public class LineSeries extends CartesianSeries
	{
		
	//--------------------------------------
	//  Class Variables
	//--------------------------------------
		
		/**
		 * @private
		 */
		private static var defaultStyles:Object =
		{
			markerSkin: CircleSkin,
			lineWeight: 3
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
		 *  Constructor.
		 */
		public function LineSeries(data:Object = null)
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
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
	
		/**
		 * @copy com.yahoo.astra.fl.charts.ISeries#clone()
		 */
		override public function clone():ISeries
		{
			var series:LineSeries = new LineSeries();
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
			series.horizontalField = this.horizontalField;
			series.verticalField = this.verticalField;
			
			return series;
		}
		
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------

		/**
		 * @private
		 */
		override protected function draw():void
		{
			super.draw();
			
			this.graphics.clear();
			
			if(!this.dataProvider) return;
			
			var markerSize:Number = this.getStyleValue("markerSize") as Number;
			
			var startValues:Array = [];
			var endValues:Array = [];
			var itemCount:int = this.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this.dataProvider[i];
				var position:Point = CartesianChart(this.chart).dataToLocal(item, this);
				
				var marker:DisplayObject = this.markers[i] as DisplayObject;
				var ratio:Number = marker.width / marker.height;
				if(isNaN(ratio)) ratio = 1;
				marker.height = markerSize;
				marker.width = marker.height * ratio;
				
				if(marker is UIComponent) 
				{
					(marker as UIComponent).drawNow();
				}
				
				//if we have a bad position, don't display the marker
				if(isNaN(position.x) || isNaN(position.y))
				{
					this.invalidateMarker(ISeriesItemRenderer(marker));
				}
				else if(this.isMarkerInvalid(ISeriesItemRenderer(marker)))
				{
					marker.x = position.x - marker.width / 2;
					marker.y = position.y - marker.height / 2;
					this.validateMarker(ISeriesItemRenderer(marker));
				}
				
				//correct start value for marker size
				startValues.push(marker.x + marker.width / 2);
				startValues.push(marker.y + marker.height / 2);
				
				endValues.push(position.x);
				endValues.push(position.y);
			}
			
			//handle animating all the markers in one fell swoop.
			if(this._animation)
			{
				this._animation.removeEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
				this._animation.removeEventListener(AnimationEvent.COMPLETE, tweenUpdateHandler);
				this._animation = null;
			}
			
			//don't animate on livepreview!
			if(this.isLivePreview || !this.getStyleValue("animationEnabled"))
			{
				this.drawMarkers(endValues);
			}
			else
			{
				var animationDuration:int = this.getStyleValue("animationDuration") as int;
				var animationEasingFunction:Function = this.getStyleValue("animationEasingFunction") as Function;
				
				this._animation = new Animation(animationDuration, startValues, endValues);
				this._animation.addEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
				this._animation.addEventListener(AnimationEvent.COMPLETE, tweenUpdateHandler);
				this._animation.easingFunction = animationEasingFunction;
				this.drawMarkers(startValues);
			}
		}
		
		private function tweenUpdateHandler(event:AnimationEvent):void
		{
			this.drawMarkers(event.parameters as Array);
		}
		
		private function drawMarkers(data:Array):void
		{
			var lineWeight:int = this.getStyleValue("lineWeight") as int;
			var fillColor:uint = this.getStyleValue("fillColor") as uint;
			this.graphics.clear();
			this.graphics.lineStyle(lineWeight, fillColor);
			
			var lastPosition:Point;
			
			//used to determine if the data must be drawn
			var seriesBounds:Rectangle = new Rectangle(0, 0, this.width, this.height);
			var lastMarkerValid:Boolean = false;
			var itemCount:int = this.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var marker:DisplayObject = this.markers[i] as DisplayObject;
				var xPosition:Number = data[i * 2] as Number;
				var yPosition:Number = data[i * 2 + 1] as Number;
				var markerValid:Boolean = !this.isMarkerInvalid(ISeriesItemRenderer(marker));
				
				//if the position is valid, move or draw as needed
				if(markerValid)
				{
					marker.x = xPosition - marker.width / 2;
					marker.y = yPosition - marker.height / 2;
					
					//if the last position is not valid, simply move to the new position
					if(!lastPosition || !lastMarkerValid)
					{
						this.graphics.moveTo(xPosition, yPosition);
					}
					else //current and last position are both valid
					{
						var minX:Number = Math.min(lastPosition.x, xPosition);
						var maxX:Number = Math.max(lastPosition.x, xPosition);
						var minY:Number = Math.min(lastPosition.y, yPosition);
						var maxY:Number = Math.max(lastPosition.y, yPosition);
						var lineBounds:Rectangle = new Rectangle(minX, minY, maxX - minX, maxY - minY);
						
						//if x or y position is equal between points, the rectangle will have
						//a width or height of zero (so no line will be drawn where one should!)
						if(lineBounds.width == 0)
						{
							lineBounds.width = 1;
						}
						
						if(lineBounds.height == 0)
						{
							lineBounds.height = 1;
						}
						
						//if line between the last point and this point is within
						//the series bounds, draw it, otherwise, only move to the new point.
						if(lineBounds.intersects(seriesBounds))
						{
							this.graphics.lineTo(xPosition, yPosition);
						}
						else this.graphics.moveTo(xPosition, yPosition);							
					}
					lastPosition = new Point(xPosition, yPosition);
					lastMarkerValid = true;
				}
				else lastMarkerValid = false;
			}
		}
		
	}
}
