package com.iflashigame.utils 
{
	import flash.utils.getTimer;
	/**
	 * 混淆的整型类
	 * @author 闪刀浪子
	 */
	public class MixInt 
	{
		private var _obj:Object;
		private var _timer:String;
		public function MixInt(val:int=0) 
		{
			_timer = getTimer().toString();
			setValue(val);
		}
		
		public function getValue():int
		{
			var str:String = _obj.value;
			_obj = { value:str };
			return int(str.substr(0,str.length-_timer.length));
		}
		
		public function setValue(val:int)
		{
			var tmpObj:Object = { value:val.toString()+_timer };
			_obj = { value:tmpObj.value };
		}
		
		public function toString():String
		{
			return getValue().toString();
		}
	}

}