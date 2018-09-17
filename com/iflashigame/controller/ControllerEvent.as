package com.iflashigame.controller 
{
	import flash.events.Event;
	
	/**
	 * 通讯控制器事件
	 * @author faster
	 */
	public class ControllerEvent extends Event 
	{
		public static const ERROR:String = "error";
		public var data:Object;
		public function ControllerEvent(type:String, obj:Object,bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			data = obj;
			super(type, bubbles, cancelable);
			
		} 
	}

}