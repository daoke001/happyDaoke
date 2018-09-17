package com.iflashigame.utils 
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.utils.Dictionary;
	/**
	 * 震动屏幕
	 * @author Faster
	 */
	public class Shake 
	{
		private static var arr:Dictionary = new Dictionary(true);
		public static function run(container:DisplayObjectContainer) 
		{
			if (arr[container] == null)
			{
				arr[container] = { };
				arr[container].x = container.x;
				arr[container].y = container.y;
				arr[container].count = 3;
				container.addEventListener(Event.ENTER_FRAME, shankEnterFrameHandler)
			}
			else
			{
				arr[container].count += 3;
			}
			
		}
		
		private static function shankEnterFrameHandler(evt:Event)
		{
			var container:DisplayObjectContainer = evt.currentTarget as DisplayObjectContainer;
			if (arr[container].count < 0)
			{
				container.removeEventListener(Event.ENTER_FRAME, shankEnterFrameHandler);
				container.x = arr[container].x;
				container.y = arr[container].y;
				delete arr[container];
			}
			else
			{
				var direct:int = arr[container].count % 2;
				if (direct == 1)
				{
					container.y = arr[container].y + arr[container].count * 2;
				}
				else
				{
					container.y = arr[container].y - arr[container].count * 2;
				}
				arr[container].count--;
			}
		}
		
	}

}