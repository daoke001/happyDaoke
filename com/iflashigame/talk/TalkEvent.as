package com.iflashigame.talk 
{
	import flash.events.Event;
	/**
	 * ...
	 * @author faster
	 */
	public class TalkEvent extends Event
	{
		public static const NET_INFO:String = "netInfo";	//私人信息
		
		public var data:Object;
		public function TalkEvent(type:String, bubbles:Boolean=false, obj:Object=null, cancelable:Boolean=false) 
		{ 
			data = obj;
			super(type, bubbles, cancelable);
		} 
		
		public override function clone():Event 
		{ 
			return new TalkEvent(type, bubbles, data, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("TalkEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}

}