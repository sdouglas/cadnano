/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.charts
{
	import com.yahoo.astra.fl.charts.series.ColumnSeries;
	import com.yahoo.astra.fl.charts.series.ISeries;
	import fl.core.UIComponent;
	
	/**
	 * A chart that displays its data points with vertical columns.
	 * 
	 * @author Josh Tynjala
	 */
	public class ColumnChart extends CartesianChart
	{
		
	//--------------------------------------
	//  Class Variables
	//--------------------------------------
		
		/**
		 * @private
		 */
		private static var defaultStyles:Object = 
		{	
			seriesMarkerSizes: [18] //make the markers a bit wider than other charts
		};
		
	//--------------------------------------
	//  Class Methods
	//--------------------------------------
	
		/**
		 * @private
		 * @copy fl.core.UIComponent#getStyleDefinition()
		 */
		public static function getStyleDefinition():Object
		{
			return mergeStyles(defaultStyles, CartesianChart.getStyleDefinition());
		}
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 * Constructor.
		 */
		public function ColumnChart()
		{
			super();
			this.defaultSeriesType = ColumnSeries;
		}
		
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
		
		/**
		 * @private
		 * Positions and updates the series objects.
		 * Columns must be positioned next to each other.
		 */
		override protected function drawSeries():void
		{
			super.drawSeries();
			var seriesCount:int = this.series.length;
			var totalMarkerSize:Number = 0;
			var maximumAllowedMarkerSize:Number = this._contentBounds.width / CategoryAxis(this.horizontalAxis).categoryNames.length / ColumnSeries.getSeriesCount(this);
			for(var i:int = 0; i < seriesCount; i++)
			{
				var series:UIComponent = UIComponent(this.series[i]);
				if(!(series is ColumnSeries)) continue;
				series.x = 0;
				var markerSize:Number = Math.floor(Math.min(maximumAllowedMarkerSize, series.getStyle("markerSize") as Number));
				totalMarkerSize += markerSize;
			}
			
			var xPosition:Number = 0;
			for(i = 0; i < seriesCount; i++)
			{
				series = UIComponent(this.series[i]);
				if(!(series is ColumnSeries)) continue;
				series.x += -(totalMarkerSize / 2) + xPosition;
				markerSize = Math.floor(Math.min(maximumAllowedMarkerSize, series.getStyle("markerSize") as Number));
				xPosition += markerSize;
			}
		}
		
	}
}
