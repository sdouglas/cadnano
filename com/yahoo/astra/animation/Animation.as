/*
Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.animation
{
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 * @eventType com.yahoo.astra.animation.AnimationEvent.START
	 */
	[Event(name="start", type="com.yahoo.astra.animation.AnimationEvent")]

	/**
	 * @eventType com.yahoo.astra.animation.AnimationEvent.UPDATE
	 */
	[Event(name="update", type="com.yahoo.astra.animation.AnimationEvent")]

	/**
	 * @eventType com.yahoo.astra.animation.AnimationEvent.COMPLETE
	 */
	[Event(name="complete", type="com.yahoo.astra.animation.AnimationEvent")]

	/**
	 * @eventType com.yahoo.astra.animation.AnimationEvent.PAUSE
	 */
	[Event(name="pause", type="com.yahoo.astra.animation.AnimationEvent")]
	
	/**
	 * An ultra lightweight animation engine.
	 * 
	 * @author Josh Tynjala
	 */
	public class Animation extends EventDispatcher
	{
		
	//--------------------------------------
	//  Class Properties
	//--------------------------------------
	
		/**
		 * @private
		 * Hash to get an Animation's target.
		 */
		private static var animationToTargets:Dictionary = new Dictionary();
		
		/**
		 * @private
		 * Hash to get the a target's Animation.
		 */
		private static var targetsToAnimation:Dictionary = new Dictionary();
	
		/**
		 * @private
		 * The main timer shared by all Animation instances.
		 */
		private static var mainTimer:Timer = new Timer(10);
	
	//--------------------------------------
	//  Class Methods
	//--------------------------------------
		
		/**
		 * Animates one or more properties of a target object. Uses the current values
		 * of these properties as the starting values.
		 *
		 * @param target		the object whose properties will be animated.
		 * @param duration		the time in milliseconds over which the properties will be animated.		 
		 * @param parameters	an object containing keys of property names on the object and the ending values.
		 * @param autoStart		if true (the default), the animation will run automatically.
		 *						if false, the returned Animation object will not automatically run, and
		 *						one must call the <code>start()</code> function.
		 */
		public static function create(target:Object, duration:int, parameters:Object, autoStart:Boolean = true):Animation
		{
			//if we're already tweening this target, remove the old tween.
			var oldAnimation:Animation = Animation.targetsToAnimation[target];
			if(oldAnimation)
			{
				oldAnimation.pause();
				removeAnimation(oldAnimation);
			}
			
			var startParameters:Object = {};
			for(var prop:String in parameters)
			{
				startParameters[prop] = target[prop];
			}
			
			var Animation:Animation = new Animation(duration, startParameters, parameters, autoStart);
			Animation.addEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
			Animation.addEventListener(AnimationEvent.COMPLETE, tweenCompleteHandler);
			
			targetsToAnimation[target] = Animation;
			animationToTargets[Animation] = target;
			return Animation;
		}
		
		/**
		 * @private
		 * Handles updating the properties on a Animation target.
		 */
		private static function tweenUpdateHandler(event:AnimationEvent):void
		{
			var Animation:Animation = event.target as Animation;
			var target:Object = animationToTargets[Animation];
			var updatedParameters:Object = event.parameters;
			for(var prop:String in updatedParameters)
			{
				target[prop] = updatedParameters[prop];
			}
		}
		
		/**
		 * @private
		 * Completes a tween for a Animation target.
		 */
		private static function tweenCompleteHandler(event:AnimationEvent):void
		{
			tweenUpdateHandler(event);
			
			var Animation:Animation = event.target as Animation;
			removeAnimation(Animation);
		}
		
		/**
		 * @private
		 * Removes an Animation and its target from management.
		 */
		private static function removeAnimation(Animation:Animation):void
		{
			var target:Object = animationToTargets[Animation];
			animationToTargets[Animation] = null;
			targetsToAnimation[target] = null;
			Animation.removeEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
			Animation.removeEventListener(AnimationEvent.COMPLETE, tweenCompleteHandler);
		}
		
		/**
		 * @private
		 * Animation uses a single global Timer to save CPU time. This function lets each
		 * individual instance listen for the timer's events.
		 */
		private static function startListenToTimer(handler:Function):void
		{
			Animation.mainTimer.addEventListener(TimerEvent.TIMER, handler, false, 0, true);
			//if this is the first listener, start the timer
			if(!Animation.mainTimer.running)
			{
				Animation.mainTimer.start();
			}
		}
		

		/**
		 * @private
		 * Animation uses a single global Timer to save CPU time. This function lets each
		 * individual instance stop listening for the timer's events.
		 */
		private static function stopListenToTimer(handler:Function):void
		{
			Animation.mainTimer.removeEventListener(TimerEvent.TIMER, handler);
			//if the timer doesn't have any more listeners, we don't need to keep it running
			if(!Animation.mainTimer.hasEventListener(TimerEvent.TIMER))
			{
				Animation.mainTimer.stop();
			}
		}
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
		
		/**
		 * Constructor.
		 * 
		 * @param duration		the time in milliseconds that the tween will run
		 * @param start			the starting values of the tween
		 * @param end			the ending values of the tween
		 * @param autoStart		if false, the tween will not run until start() is called
		 */
		public function Animation(duration:int, start:Object, end:Object, autoStart:Boolean = true)
		{
			super();
			this._duration = duration;
			this._startParameters = start;
			this.endParameters = end;
			
			if(autoStart)
			{
				this.start();
			}
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
		
		/**
		 * @private
		 * Storage for the active property.
		 */
		private var _active:Boolean = false;
		
		/**
		 * If true, the animation is currently running.
		 */
		public function get active():Boolean
		{
			return this._active;
		}
		
		/**
		 * @private
		 * The time at which the animation last started running. If it has been paused
		 * one or more times, this value is reset to the restart time.
		 */
		private var _startTime:int;
		
		/**
		 * @private
		 * If the animation is paused, the running time is saved here.
		 */
		private var _savedRuntime:int;
		
		/**
		 * @private
		 * Storage for the duration property.
		 */
		private var _duration:int;
		
		/**
		 * The duration in milliseconds that the animation will run.
		 */
		public function get duration():int
		{
			return this._duration;
		}
		
		/**
		 * @private
		 * Storage for the starting values.
		 */
		private var _startParameters:Object;
		
		/**
		 * @private
		 * Storage for the ending values.
		 */
		private var _endParameters:Object;
		
		/**
		 * @private
		 * Used to determine the "ranges" between starting and ending values.
		 */
		protected function get endParameters():Object
		{
			return this._endParameters;
		}
		
		/**
		 * @private
		 */
		protected function set endParameters(value:Object):void
		{
			this._ranges = {};
			for(var prop:String in value)
			{
				var startValue:Number = Number(this._startParameters[prop]);
				var endValue:Number = Number(value[prop]);
				var range:Number = endValue - startValue;
				this._ranges[prop] = range;
			}
			this._endParameters = value;
		}
		
		/**
		 * @private
		 * The difference between the startParameters and endParameters values.
		 */
		private var _ranges:Object;
		
		/**
		 * @private
		 * Storage for the easingFunction property.
		 */
		private var _easingFunction:Function = function(t:Number, b:Number, c:Number, d:Number):Number
		{
			return (t == d)
				? b + c
				: c * 1.001 * (-Math.pow(2, -10 * t / d) + 1) + b;
		}

		/**
		 * @private
		 * The function used to ease the animation.
		 */
		public function get easingFunction():Function
		{
			return this._easingFunction;
		}
		
		/**
		 * @private
		 */
		public function set easingFunction(value:Function):void
		{
			this._easingFunction = value;
		}
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------

		/**
		 * Starts the tween. Should be used to restart a paused tween, or to
		 * start a new tween with autoStart disabled.
		 */
		public function start():void
		{
			Animation.startListenToTimer(this.timerUpdateHandler);
			this._startTime = getTimer();
			this._active = true;
			this.dispatchEvent(new AnimationEvent(AnimationEvent.START, this._startParameters));
		}
		
		/**
		 * Pauses a tween so that it may be restarted again with the same
		 * timing.
		 */
		public function pause():void
		{
			Animation.stopListenToTimer(this.timerUpdateHandler);
			this._savedRuntime += getTimer() - this._startTime;
			this._active = false;
			
			this.dispatchEvent(new AnimationEvent(AnimationEvent.PAUSE, update(this._savedRuntime)));
		}
		
		/**
		 * Forces a tween to its completion values.
		 */
		public function end():void
		{
			Animation.stopListenToTimer(this.timerUpdateHandler);
			this._active = false;
			this.dispatchEvent(new AnimationEvent(AnimationEvent.COMPLETE, this.endParameters));
		}
		
	//--------------------------------------
	//  Private Methods
	//--------------------------------------
	
		/**
		 * @private
		 */
		private function timerUpdateHandler(event:TimerEvent):void
		{
			var runtime:int = this._savedRuntime + getTimer() - this._startTime;
			if(runtime >= this._duration)
			{
				this.end();
				return;
			}
			
			this.dispatchEvent(new AnimationEvent(AnimationEvent.UPDATE, this.update(runtime)));
		}
	
		/**
		 * @private
		 * Generates updated values for the animation based on the current time.
		 */
		private function update(runtime:int):Object
		{
			//can easily handle parameters as hashes or Arrays.
			var updated:Object;
			if(this._startParameters is Array) updated = [];
			else updated = {};
			for(var prop:String in this._ranges)
			{
				var startValue:Number = this._startParameters[prop] as Number;
				var range:Number = this._ranges[prop];
				updated[prop] = this._easingFunction(runtime, startValue, range, this._duration);
			}
			return updated;
		}
		
	}
}