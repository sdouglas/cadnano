/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.charts
{
	import fl.core.UIComponent;
	import com.yahoo.astra.fl.charts.series.ISeries;
	import com.yahoo.astra.fl.charts.series.LineSeries;
	import com.yahoo.astra.fl.charts.skins.*;
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
	/**
     * The weight, in pixels, of the line drawn between points in each series.
     *
     * @default [3]
     */
    [Style(name="seriesLineWeights", type="Array")]
	
	/**
	 * A chart that displays its data points with connected line segments.
	 * 
	 * @author Josh Tynjala
	 */
	public class LineChart extends CartesianChart
	{
		
	//--------------------------------------
	//  Class Variables
	//--------------------------------------
		
		/**
		 * @private
		 */
		private static var defaultStyles:Object = 
			{	
				seriesLineWeights: [3],
				seriesMarkerSkins: [CircleSkin, DiamondSkin, RectangleSkin, TriangleSkin]
			};
			
		/**
		 * @private
		 * The chart styles that correspond to styles on each series.
		 */
		private static const LINE_SERIES_STYLES:Object = 
			{
				lineWeight: "seriesLineWeights"
			};
		
	//--------------------------------------
	//  Class Methods
	//--------------------------------------
	
		/**
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
		public function LineChart()
		{
			super();
			this.defaultSeriesType = LineSeries;
		}
		
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
		
		/**
		 * @private
		 */
		override protected function refreshSeries():void
		{
			super.refreshSeries();
			
			var seriesCount:int = this.series.length;
			for(var i:int = 0; i < seriesCount; i++)
			{
				var currentSeries:ISeries = this.series[i] as ISeries;
				this.copyStylesToSeries(currentSeries, LINE_SERIES_STYLES);
			}
		}
	}
}
