/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.fl.managers
{
    import com.yahoo.astra.fl.controls.containerClasses.DialogBox;
    import flash.display.Sprite;
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import fl.core.UIComponent;
    import flash.filters.BitmapFilterQuality;
    import flash.filters.BlurFilter;
    import flash.filters.BitmapFilter;
    import flash.text.TextField;
    import flash.text.TextFieldType;

    //--------------------------------------
    //  Class description
    //--------------------------------------
    
    /**
     * The AlertManager class extends UIComponent and manages the queuing
     * and displaying of Alerts.
     *
     * @see fl.core.UIComponent
     *
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
     * @author Dwight Bridges   
     */
    public class AlertManager extends UIComponent
    {
        
    //--------------------------------------
    //  Constructor
    //--------------------------------------
    
        /**
         * @private (singleton constructor)
         * 
         * @param container - object calling the alert
         */
        public function AlertManager(container:DisplayObject = null)
        {
            if(_allowInstantiation)
            {
                super();
                if(container != null)
                {
                    _stage = container.stage;
                }
                else
                {
                    _stage = stage;
                    parent.removeChild(this);
                    _allowInstantiation = false;
                }
                _stage.addChild(this);
                _overlay = new Sprite();
                addChild(_overlay);
                _overlay.visible = false;
                _stage.addEventListener(Event.RESIZE, stageResizeHandler, false, 0, true);
                _stage.addEventListener(Event.FULLSCREEN, stageResizeHandler, false, 0, true);  
                if(isLivePreview)
                {
                    minWidth = 100;
                    createAlert(this, " ", "  ", ["   "]);
                }
            }
        }
        
    //--------------------------------------
    //  Properties
    //--------------------------------------
         
        /**
         * @private 
         */
        //array containing an object for each alert requested by the createAlert method
        //the object contains parameters for the dialog box
        private static var _dialogBoxQueue:Array = [];
        
        /**
         * @private 
         */
        private static var _dialogBox:DialogBox;
        
        
        /**
         * @private 
         */
        private static var _dialogBoxManager:AlertManager;
        
        /**
         * @private
         */
        private static var _stage:Stage;
        
        /**
         * @private
         */
        //used to enforce singleton class
        private static var _allowInstantiation:Boolean = true;
        
        /**
         * Alpha value of the overlay
         */
        public static var overlayAlpha:Number = .2;
        
        /**
         * The blur value of the parent object when the alert is present and modal
         */
        public static var modalBackgroundBlur:int = 2;
           
        /**
         * Maximum width of the alert
         */
        public static var maxWidth:int = 800;
        
        /**
         * Minimum width of the alert 
         */
        public static var minWidth:int = 300;
        
        /**
         * Padding for the alert
         */
        public static var padding:int = 10;
        
        /**
         * Amount of space between buttons on the alert
         */
        public static var buttonSpacing:int = 2;
        
        /**
         * Amount of space between button rows on the alert
         */
        public static var buttonRowSpacing:int = 1;
        
        /**
         * Height of the buttons on the alert
         */
        public static var buttonHeight:int = 20;
        
        /**
         * Color of the text for the title bar on the alert
         */
        public static var titleTextColor:uint = 0xffffff;
        
        /**
         * Color of the message text on the alert
         */
        public static var textColor:uint = 0xffffff;
        
        /**
         * Indicates whether the alert has a drop shadow
         */
        public static var hasDropShadow:Boolean = true;
        
        /**
         * direction of the alert's drop shadow
         */
        public static var shadowDirection:String = "right";
        
        /**
         * @private
         */
        private static var _overlay:Sprite;
        
        /**
         * The DisplayObject that uses the createAlert method to display an alert.  The 
         * AlertManager 
         */
        protected var container:DisplayObject;
        
        /**
         * @private (protected)
         */
        //Copy of container's filters property.  Used to return the container to it's original 
        //state when the alert is removed.
        protected var parentFilters:Array;
        
    //--------------------------------------
    //  Public Methods
    //--------------------------------------
        
        /**
         * Creates an alert and puts it in the queue.  If it is the first alert or all 
         * previous alerts have been displayed, it will show the alert.  If this is the 
         * first alert, the class is instantiated. 
         *
         * @param container - display object creating an alert box
         * @param message - message to be displayed
         * @param title - text to show in the title bar
         * @param buttons - array containing the name of the buttons to be displayed
         * @param callBackFunction - function to be called when a button is pressed
         * @param iconClass - string value indicating the library object to be used for an icon
         * @param isModal - boolean indicating whether or not to prevent interaction with the parent while the message box is present
         *
         * @return AlertManager
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        public static function createAlert(container:DisplayObject,
                            message:String, 
                            title:String = "Alert", 
                            buttons:Array = null, 
                            callBackFunction:Function = null, 
                            iconClass:String = null, 
                            isModal:Boolean = true,
                            props:Object = null,
                            type:String = TextFieldType.DYNAMIC,
                            content:Sprite = null):AlertManager
        {   
            
            if(_dialogBoxManager == null) 
            {
                _allowInstantiation = true;
                _dialogBoxManager = new AlertManager(container);
                _dialogBox = new DialogBox(_stage,type);
                _dialogBoxManager.addChild(_dialogBox);
                _allowInstantiation = false;
            }
            
            if(buttons == null) buttons = ["OK"];
            var functions:Array = [];
            if(callBackFunction != null) functions.push(callBackFunction);
            functions.push(_dialogBoxManager.manageQueue);
            var alertParams:Object = {
                message:message, 
                title:title, 
                isModal:isModal, 
                buttons:buttons, 
                functions:functions, 
                iconClass:iconClass, 
                props:props,
                content:content,
                type:type,
                container:container
            };
            
            if(_dialogBoxQueue.length == 0)
            {
                _dialogBox.maxWidth = (props != null && !isNaN(props.maxWidth))?Math.round(props.maxWidth) as int:maxWidth;
                _dialogBox.minWidth = (props != null && !isNaN(props.minWidth))?Math.round(props.minWidth) as int:minWidth;
                _dialogBox.padding = (props != null && !isNaN(props.padding))?Math.round(props.padding) as int:padding;
                _dialogBox.buttonHeight = (props != null && !isNaN(props.buttonHeight))?Math.round(props.buttonHeight) as int:buttonHeight;
                _dialogBox.buttonRowSpacing = (props != null && !isNaN(props.buttonRowSpacing))?Math.round(props.buttonRowSpacing) as int:buttonRowSpacing;
                _dialogBox.buttonSpacing = (props != null && !isNaN(props.buttonSpacing))?Math.round(props.buttonSpacing) as int:buttonSpacing;
                _dialogBox.titleTextColor = (props != null && !isNaN(props.titleTextColor))?props.titleTextColor as uint:titleTextColor;
                _dialogBox.hasDropShadow = (props != null && props.hasDropShadow != null)?props.hasDropShadow:hasDropShadow;
                _dialogBox.shadowDirection = (props != null && props.shadowDirection != null)?props.shadowDirection:shadowDirection;
                _dialogBox.textColor = (props != null && !isNaN(props.textColor))?props.textColor as uint:textColor;
                _dialogBox.update(message, title, buttons, functions, content, type);
                _overlay.visible = isModal;
                if(isModal)
                {
                    _dialogBoxManager.container = container; 
                    var newFilters:Array;
                    newFilters = _dialogBoxManager.container.filters.concat();
                     _dialogBoxManager.parentFilters = _dialogBoxManager.container.filters.concat();
                    newFilters.push(_dialogBoxManager.getBlurFilter()); 
                    _dialogBoxManager.container.filters = newFilters;
                }
            }
            
            _dialogBoxQueue.push(alertParams);
            
            return _dialogBoxManager;
        }
        
        /**
         * Removes the current alert from the messages array.  If there are more alerts, 
         * call pass the params for the next alert to the DialogBox object.  Otherwise, 
         * hide the alert object and the cover.</p>
         *
         * @evnt - Mouse event received from the DialogBox object 
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */ 
        public function manageQueue(evnt:MouseEvent):void
        {       
            _dialogBoxQueue.splice(0, 1);
            _dialogBoxManager.container.filters = _dialogBoxManager.parentFilters;
            if(_dialogBoxQueue.length > 0)
            {
                _stage.setChildIndex(this, _stage.numChildren - 1);
                var params:Object = _dialogBoxQueue[0];
                var props:Object = params.props;
                _dialogBox.maxWidth = (props != null && !isNaN(props.maxWidth))?Math.round(props.maxWidth) as int:maxWidth;
                _dialogBox.minWidth = (props != null && !isNaN(props.minWidth))?Math.round(props.minWidth) as int:minWidth;
                _dialogBox.padding = (props != null && !isNaN(props.padding))?Math.round(props.padding) as int:padding;
                _dialogBox.buttonHeight = (props != null && !isNaN(props.buttonHeight))?Math.round(props.buttonHeight) as int:buttonHeight;
                _dialogBox.buttonRowSpacing = (props != null && !isNaN(props.buttonRowSpacing))?Math.round(props.buttonRowSpacing) as int:buttonRowSpacing;
                _dialogBox.buttonSpacing = (props != null && !isNaN(props.buttonSpacing))?Math.round(props.buttonSpacing) as int:buttonSpacing;
                _dialogBox.titleTextColor = (props != null && !isNaN(props.titleTextColor))?props.titleTextColor as uint:titleTextColor;
                _dialogBox.textColor = (props != null && !isNaN(props.textColor))?props.textColor as uint:textColor;
                _dialogBox.hasDropShadow = (props != null && props.hasDropShadow != null)?props.hasDropShadow:hasDropShadow;
                _dialogBox.shadowDirection = (props != null && props.shadowDirection != null)?props.shadowDirection:shadowDirection;
                _dialogBox.update(params.message, params.title, params.buttons, params.functions, params.content, params.type);
                _overlay.visible = params.isModal;
                if(params.isModal)
                {
                    _dialogBoxManager.container = params.container; 
                    var newFilters:Array;
                    newFilters = _dialogBoxManager.container.filters.concat();
                     _dialogBoxManager.parentFilters = _dialogBoxManager.container.filters.concat();
                    newFilters.push(_dialogBoxManager.getBlurFilter()); 
                    _dialogBoxManager.container.filters = newFilters;
                }
            }
            else
            {
                _dialogBox.visible = false;
                _overlay.visible = false;
            }
        }
        
        /**
         * Gets a blur filter to add to the parent's <code>filters</code> property.
         *
         * @return BitmapFilter with specified blur values
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        public function getBlurFilter():BitmapFilter
        {
            var blurFilter:BlurFilter = new BlurFilter();
            blurFilter.blurX = modalBackgroundBlur;
            blurFilter.blurY = modalBackgroundBlur;
            blurFilter.quality = BitmapFilterQuality.HIGH;
            return blurFilter;
        }
        
        
    //--------------------------------------
    //  Protected Methods
    //-------------------------------------
    
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        protected override function configUI():void
        {
            super.configUI();

        }
        
        /**
         * @private (protected)
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */ 
        //Set the width and height to that of the stage and redraw the cover object. 
        protected override function draw():void
        {
            //set the dimensions
            this.width = _stage.stageWidth;
            this.height = _stage.stageHeight;
            this.x = _stage.x;
            this.y = _stage.y;
            _overlay.x = _overlay.y = 0;
            _overlay.width = this.width;
            _overlay.height = this.height;
            _overlay.graphics.clear();
            _overlay.graphics.beginFill(0xeeeeee, overlayAlpha);
            _overlay.graphics.moveTo(0,0);
            _overlay.graphics.lineTo(this.width, 0);
            _overlay.graphics.lineTo(this.width, this.height);
            _overlay.graphics.lineTo(0, this.height);
            _overlay.graphics.lineTo(0, 0);
            _overlay.graphics.endFill();
            if(_dialogBox != null) _dialogBox.positionAlert();
        }
        
        /**
         * @private (protected)
         *
         * @param evnt - event fired from the stage
         *
         * @langversion 3.0
         * @playerversion Flash 9.0.28.0
         */
        //Call the draw function when the stage is resized
        protected function stageResizeHandler(evnt:Event):void
        {
            draw();
        }
        public function get textField():TextField
        {
            return _dialogBox.textField;
        }
    }
}