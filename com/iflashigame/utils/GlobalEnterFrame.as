package com.iflashigame.utils 
{
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Faster
	 */
	public class GlobalEnterFrame extends Sprite 
	{
		private static var _instance:GlobalEnterFrame;
		public function GlobalEnterFrame() 
		{
			
		}
		
		public static function getInstance():GlobalEnterFrame
		{
			if (GlobalEnterFrame._instance == null)
			{
				GlobalEnterFrame._instance = new GlobalEnterFrame(new SingletonEnforcer);
			}
			return GlobalEnterFrame._instance;
		}
		
	}

}
class SingletonEnforcer{}