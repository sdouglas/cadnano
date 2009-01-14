/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.controls
{
	import com.yahoo.astra.fl.controls.tabBarClasses.TabButton;
	import com.yahoo.astra.fl.events.TabBarEvent;
	
	import fl.core.UIComponent;
	import fl.data.DataProvider;
	import fl.data.SimpleCollectionItem;
	import fl.events.DataChangeEvent;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;

    //--------------------------------------
    //  Events
    //--------------------------------------
	
	/**
	 * Dispatched when the user rolls the pointer off of an tab in the component.
     *
	 * @eventType com.yahoo.astra.fl.events.TabBarEvent.ITEM_ROLL_OUT
     *
     * @see #event:itemRollOver
	 */
	[Event(name="itemRollOut", type="com.yahoo.astra.fl.events.TabBarEvent")]
	
	/**
	 * Dispatched when the user rolls the pointer over an tab in the component.
     *
     * @eventType com.yahoo.astra.fl.events.TabBarEvent.ITEM_ROLL_OVER
     *
     * @see #event:itemRollOut
	 */
	[Event(name="itemRollOver", type="com.yahoo.astra.fl.events.TabBarEvent")]
	
	/**
	 * Dispatched when the user rolls the pointer over the component.
	 * 
	 * @eventType flash.events.MouseEvent.ROLL_OVER
     *
     * @see #event:rollOut
	 */
	[Event(name="rollOver", type="flash.events.MouseEvent")]
	
	/**
	 * Dispatched when the user rolls the pointer off of the component.
     *
	 * @eventType flash.events.MouseEvent.ROLL_OUT
     *
     * @see #event:rollOver
	 */
	[Event(name="rollOut", type="flash.events.MouseEvent")]
	
	/**
     * Dispatched when the user clicks an item in the component. 
	 *
	 * <p>The <code>click</code> event is dispatched before the value
	 * of the component is changed. To identify the tabs that was clicked,
	 * use the properties of the event object; do not use the <code>selectedIndex</code> 
     * and <code>selectedItem</code> properties.</p>
     *
     * @eventType com.yahoo.astra.fl.events.TabBarEvent.ITEM_CLICK
	 */
	[Event(name="itemClick", type="com.yahoo.astra.fl.events.TabBarEvent")]
	
	/**
	 * Dispatched when a different item is selected in the TabBar.
     *
     * @eventType flash.events.Event.CHANGE
	 */
	[Event(name="change", type="flash.events.Event")]
	

    //--------------------------------------
    //  Styles
    //--------------------------------------
    
	/**
	 * A collection of buttons, or tabs, that may be used for navigation.
	 * 
     * @see fl.data.DataProvider
	 */
	public class TabBar extends UIComponent
	{
			
	//--------------------------------------
	//  Static Properties
	//--------------------------------------
	
		/**
		 * @private
		 */
		private static const TAB_STYLES:Object = 
		{
			embedFonts: "embedFonts",
			disabledTextFormat: "disabledTextFormat",
			textFormat: "textFormat",
			textPadding: "textPadding"
		};
		
	//--------------------------------------
	//  Static Methods
	//--------------------------------------
	
		/**
		 * @private
		 * Creates the Accessibility class.
         * This method is called from UIComponent.
		 */
		public static var createAccessibilityImplementation:Function;
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 * Constructor.
		 */
		public function TabBar()
		{
			super();
			this.addEventListener(KeyboardEvent.KEY_DOWN, navigationKeyDownHandler);
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
		
		/**
		 * @private
		 * Displays a message in live preview mode when there is no dataProvider.
		 */
		private var _livePreviewMessage:TabButton;
		
		/**
		 * @private
		 * When redrawing, buttons are saved in this cache for reuse.
		 */
		protected var _cachedButtons:Array = [];
		
		/**
		 * @private
		 * Storage for the buttons displayed in the TabBar.
		 */
		protected var _buttons:Array = [];
		
		/**
		 * @private
		 * Storage for the focusIndex property.
		 */
		protected var _focusIndex:int = 0;
		
		/**
		 * @private
		 * The index of the currently focused tab (used for keyboard navigation).
		 */
		public function get focusIndex():int
		{
			return this._focusIndex;
		}
		
		/**
		 * @private
		 */
		public function set focusIndex(value:int):void
		{
			this._focusIndex = value;
			this.invalidate("focus");
				
			//internal event used for accessibility
			//similar implementation in Flex TabBar control.
			this.dispatchEvent(new Event("focusUpdate"));
		}
		
		/**
		 * @private
		 * Like fl.controls.List, the purpose of this variable is
		 * only to make sure the SimpleCollectionItem is included.
		 */
		private var collectionItemImport:SimpleCollectionItem;
		
		/**
		 * @private
		 * Storage for the dataProvider property.
		 */
		protected var _dataProvider:DataProvider;
		
		/**
		 * Gets or sets the data model of the list of items to be viewed. A data provider 
		 * can be shared by multiple list-based components. Changes to the data provider 
		 * are immediately available to all components that use it as a data source. 
		 *  
		 * @default null
		 */
		public function get dataProvider():DataProvider
		{
			return this._dataProvider;
		}
		
		[Collection(collectionClass="fl.data.DataProvider", collectionItem="fl.data.SimpleCollectionItem", identifier="item")]
		/**
         * @private
		 */
		public function set dataProvider(value:DataProvider):void
		{
			if(this._dataProvider)
			{
				this._dataProvider.removeEventListener(DataChangeEvent.DATA_CHANGE, dataChangeHandler);
			}
			
			this._dataProvider = value;
			
			if(this._dataProvider)
			{
				this._dataProvider.addEventListener(DataChangeEvent.DATA_CHANGE, dataChangeHandler, false, 0, true);
			}
			
			this.invalidate();
		}
		
		/**
		 * @private
		 * Storage for the labelField property.
		 */
		protected var _labelField:String = "label";
		
		/**
         * Gets or sets the name of the field in the <code>dataProvider</code> object 
         * to be displayed as the label in the tabs. 
		 *
         * <p>By default, the component displays the <code>label</code> property 
		 * of each <code>dataProvider</code> item. If the <code>dataProvider</code> 
		 * items do not contain a <code>label</code> property, you can set the 
		 * <code>labelField</code> property to use a different property.</p>
         *
         * <p><strong>Note:</strong> The <code>labelField</code> property is not used 
         * if the <code>labelFunction</code> property is set to a callback function.</p>
         * 
         * @default "label"
         *
         * @see #labelFunction
		 */
		public function get labelField():String
		{
			return this._labelField;	
		}
		
		/**
         * @private
		 */
		public function set labelField(value:String):void
		{
			if(this._labelField != value)
			{
				this._labelField = value;
				this.invalidate();
			}
		}
		
		/**
		 * @private
		 * Storage for the labelFunction property.
		 */
		protected var _labelFunction:Function = null;
		
        /**
         * Gets or sets the function to be used to obtain the label for the item.
		 *
         * <p>By default, the component displays the <code>label</code> property
		 * for a <code>dataProvider</code> item. But some data sets may not have 
		 * a <code>label</code> field or may not have a field whose value
		 * can be used as a label without modification. For example, a given data 
		 * set might store full names but maintain them in <code>lastName</code> and  
		 * <code>firstName</code> fields. In such a case, this property could be
		 * used to set a callback function that concatenates the values of the 
		 * <code>lastName</code> and <code>firstName</code> fields into a full 
		 * name string to be displayed.</p>
		 *
         * <p><strong>Note:</strong> The <code>labelField</code> property is not used 
         * if the <code>labelFunction</code> property is set to a callback function.</p>
         *
         * @default null
		 */
		public function get labelFunction():Function
		{
			return this._labelFunction;	
		}
		
		/**
         * @private
		 */
		public function set labelFunction(value:Function):void
		{
			if(this._labelFunction != value)
			{
				this._labelFunction = value;
				this.invalidate();
			}
		}
		
		/**
		 * @private
		 * Storage for the selectedIndex property.
		 */
		protected var _selectedIndex:int = 0;
		
		/**
		 * Gets or sets the index of the tab that is selected. Only one item can be selected 
		 * at a time. 
		 *
		 * <p>A value of -1 indicates that no tab is selected.</p>
		 *
		 * <p>When ActionScript is used to set this property, the item at the specified index
		 * replaces the current selection. When the selection is changed programmatically, 
		 * a <code>change</code> event object is not dispatched. </p>
         *
         * @see #selectedItem
		 *  
		 * @default 0
		 */
		public function get selectedIndex():int
		{
			return this._selectedIndex;
		}
		
		/**
         * @private
		 */
		public function set selectedIndex(value:int):void
		{
			if(value >= this._dataProvider.length) value = -1;
			if(this._selectedIndex != value)
			{
				this._selectedIndex = value;
				this.focusIndex = value;
				this.invalidate();
				this.dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		/**
		 * Gets or sets the item that was selected. 
		 *
		 * <p>If no selection is made, the value of this property is <code>null</code>.</p>
         *
         * @see #selectedIndex
		 */
		public function get selectedItem():Object
		{
			if(this.selectedIndex >= 0)
			{
				return this._dataProvider.getItemAt(this.selectedIndex);
			}
			return null;
		}
		
		/**
         * @private
		 */
		public function set selectedItem(value:Object):void
		{
			var index:int = this._dataProvider.getItemIndex(value);
			this.selectedIndex = index;
		}
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
		
		/**
		 * Returns the index of the given data object.
		 * 
		 * @param	item	The object to be rendered.
		 * @return the index of the object in the data provider. -1 if it cannot be found.
		 */
		public function itemToIndex(item:Object):int
		{
			return this._dataProvider.getItemIndex(item);
		}
		
		/**
		 * Retrieves the string that the renderer displays for the given data object 
         * based on the <code>labelField</code> and <code>labelFunction</code> properties.
         *
         * <p><strong>Note:</strong> The <code>labelField</code> is not used  
         * if the <code>labelFunction</code> property is set to a callback function.</p>
		 *
		 * @param item	The object to be rendered.
		 *
         * @return	The string to be displayed based on the data.
		 */
		public function itemToLabel(item:Object):String
		{
			if(this.labelFunction != null)
			{
				this.labelFunction(item, this.itemToIndex(item));
			}
			else if(this.labelField && item.hasOwnProperty(this.labelField))
			{
				return item[this.labelField];
			}
			return "";
		}
		
		/**
		 * Returns the data object corresponding to an index.
		 * 
		 * @param	index	a zero-based index
		 * @return	the item at the specified index within the data provider.
		 */
		public function indexToItem(index:int):Object
		{
			return this._dataProvider.getItemAt(index);
		}
		
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
	
        /**
         * @private
		 */
		override protected function initializeAccessibility():void
		{
			if(TabBar.createAccessibilityImplementation != null)
			{
				TabBar.createAccessibilityImplementation(this);
			}
		}
		
		/**
		 * @private
		 */
		override protected function configUI():void
		{
			super.configUI();
			if(this.isLivePreview)
			{
				//special case for live previews with no data.
				this._livePreviewMessage = new TabButton();
				this._livePreviewMessage.label = "No live preview data";
				this.addChild(this._livePreviewMessage);
			}
		}
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			if(this.isLivePreview)
			{
				this._livePreviewMessage.visible = !this.dataProvider || this.dataProvider.length == 0;
				this._livePreviewMessage.height = this.height;
				this._livePreviewMessage.drawNow();
			}
			
			this.createCache();
			if(this._dataProvider)
			{
				this.drawButtons();
			}
			this.clearCache();
			
			if(this.isInvalid("focus") && this.focusIndex >= 0 && this.focusIndex < this._buttons.length)
			{
				var button:UIComponent = UIComponent(this._buttons[this.focusIndex]);
				button.setFocus();
			}
			
			super.draw();
		}
		
		/**
		 * @private
		 * 
		 * Updates the position and size of the buttons.
		 */
		protected function drawButtons():void
		{
			var xPosition:Number = 0;
			var buttonCount:int = this._dataProvider.length;
			for(var i:int = 0; i < buttonCount; i++)
			{
				var button:TabButton = this.getButton();
				this._buttons.push(button);
				
				var item:Object = this._dataProvider.getItemAt(i);
				button.label = this.itemToLabel(item);
				button.selected = this._selectedIndex == i;
				if(i == this._focusIndex)
				{
					button.setMouseState("over");
				}
				else if(i == this._selectedIndex)
				{
					button.setMouseState("down");
				}
				else
				{
					button.setMouseState("up");
				}
				
				button.x = xPosition;
				this.copyStylesToChild(button, TAB_STYLES);
				button.height = this.height;
				button.drawNow();
				
				xPosition += button.width;
			}
			//width changes automatically based on the size of the tabs.
			this.width = xPosition;
		}
		
		/**
		 * @private
		 * 
		 * Either retrieves a button from the cache or creates a new one.
		 */
		protected function getButton():TabButton
		{
			var button:TabButton;
			if(this._cachedButtons.length > 0)
			{
				button = this._cachedButtons.shift() as TabButton;
			}
			else
			{
				button = new TabButton();	
				button.toggle = true;		
				button.addEventListener(Event.CHANGE, buttonChangeHandler, false, 0, true);
				button.addEventListener(MouseEvent.CLICK, buttonClickHandler, false, 0, true);
				button.addEventListener(MouseEvent.ROLL_OVER, buttonRollOverHandler, false, 0, true);
				button.addEventListener(MouseEvent.ROLL_OUT, buttonRollOutHandler, false, 0, true);
				this.addChild(button);
			}
			return button;
		}
		
		/**
		 * @private
		 * 
		 * Saves the buttons from the last redraw so that they may be reused.
		 */
		protected function createCache():void
		{
			this._cachedButtons = this._buttons.concat();
			this._buttons = [];
		}
		
		/**
		 * @private
		 * 
		 * Removes unneeded buttons that were cached for a redraw.
		 */
		protected function clearCache():void
		{
			var cacheLength:int = this._cachedButtons.length;
			for(var i:int = 0; i < cacheLength; i++)
			{
				var button:TabButton = this._cachedButtons.pop() as TabButton;
				button.removeEventListener(Event.CHANGE, buttonChangeHandler);
				button.removeEventListener(MouseEvent.CLICK, buttonClickHandler);
				button.removeEventListener(MouseEvent.ROLL_OVER, buttonRollOverHandler);
				button.removeEventListener(MouseEvent.ROLL_OUT, buttonRollOutHandler);
				this.removeChild(button);
			}
		}
		
		/**
		 * @private
		 * 
		 * Requests a redraw when the data provider changes.
		 */
		protected function dataChangeHandler(event:DataChangeEvent):void
		{
			this.invalidate();
		}
		
		/**
		 * @private
		 * Listen for events to allow for keyboard navigation.
		 */
		protected function navigationKeyDownHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				//down and right goes to next tab
				case Keyboard.DOWN:
				case Keyboard.RIGHT:
					if(this.numChildren == 0)
					{
						this.focusIndex = -1;
					}
					else if(this.focusIndex == this.numChildren - 1)
					{
						this.focusIndex = 0;
					}
					else this.focusIndex++;
					break;
				//up and left goes to previous tab
				case Keyboard.UP:
				case Keyboard.LEFT:
					if(this.focusIndex == 0)
					{
						this.focusIndex = this.numChildren - 1;
					}
					else this.focusIndex--;
					break;
			}
		}
		
		/**
		 * @private
		 * 
		 * Captures change events from each button and resets the selected index
		 * to match the last-selected button.
		 */
		protected function buttonChangeHandler(event:Event):void
		{
			var changedButton:TabButton = event.target as TabButton;
			if(changedButton.selected)
			{
				var index:int = this._buttons.indexOf(changedButton);
				this.selectedIndex = index;
			}
		}
		
		/**
		 * @private
		 * 
		 * Captures click events from each button, and dispatches the
		 * TabBarEvent.ITEM_CLICK event to listeners.
		 */
		protected function buttonClickHandler(event:MouseEvent):void
		{
			var button:TabButton = event.currentTarget as TabButton;
			var index:int = this._buttons.indexOf(button);
			var item:Object = this._dataProvider.getItemAt(index);
			this.dispatchEvent(new TabBarEvent(TabBarEvent.ITEM_CLICK, false, false, index, item));
		}
		
		/**
		 * @private
		 * 
		 * Captures roll-over events from each button, and dispatches the
		 * TabBarEvent.ITEM_ROLL_OVER event to listeners.
		 */
		protected function buttonRollOverHandler(event:MouseEvent):void
		{
			var button:TabButton = event.currentTarget as TabButton;
			var index:int = this._buttons.indexOf(button);
			var item:Object = this._dataProvider.getItemAt(index);
			this.dispatchEvent(new TabBarEvent(TabBarEvent.ITEM_ROLL_OVER, false, false, index, item));
		}
		
		/**
		 * @private
		 * 
		 * Captures roll-out events from each button, and dispatches the
		 * TabBarEvent.ITEM_ROLL_OUT event to listeners.
		 */
		protected function buttonRollOutHandler(event:MouseEvent):void
		{
			var button:TabButton = event.currentTarget as TabButton;
			var index:int = this._buttons.indexOf(button);
			var item:Object = this._dataProvider.getItemAt(index);
			this.dispatchEvent(new TabBarEvent(TabBarEvent.ITEM_ROLL_OUT, false, false, index, item));
		}
	}
}