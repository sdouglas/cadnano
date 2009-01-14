/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.charts.series
{
	import flash.events.Event;
	import com.yahoo.astra.fl.charts.series.Series;

	/**
	 * Functionality common to most series appearing in cartesian charts.
	 * Generally, a <code>CartesianSeries</code> object shouldn't be
	 * instantiated directly. Instead, a subclass with a concrete implementation
	 * should be used.
	 * 
	 * @author Josh Tynjala
	 */
	public class CartesianSeries extends Series
	{
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 * Constructor.
		 */
		public function CartesianSeries(data:Object = null)
		{
			super(data);
		}
	
	//--------------------------------------
	//  Properties
	//--------------------------------------
		
		/**
		 * @private
		 * Storage for the horizontalField property.
		 */
		private var _horizontalField:String;
		
		/**
		 * @copy com.yahoo.astra.fl.charts.ISeries#horizontalField
		 */
		public function get horizontalField():String
		{
			return this._horizontalField;
		}
		
		/**
		 * @private
		 */
		public function set horizontalField(value:String):void
		{
			if(this._horizontalField != value)
			{
				this._horizontalField = value;
				this.dispatchEvent(new Event("dataChange"));
			}
		}
		
		/**
		 * @private
		 * Storage for the verticalField property.
		 */
		private var _verticalField:String;
		
		/**
		 * @copy com.yahoo.astra.fl.charts.ISeries#verticalField
		 */
		public function get verticalField():String
		{
			return this._verticalField;
		}
		
		/**
		 * @private
		 */
		public function set verticalField(value:String):void
		{
			if(this._verticalField != value)
			{
				this._verticalField = value;
				this.dispatchEvent(new Event("dataChange"));
			}
		}
		
	}
}